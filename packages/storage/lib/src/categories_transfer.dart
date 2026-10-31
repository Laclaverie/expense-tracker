import 'package:core/core.dart' as core;
import 'package:drift/drift.dart';

import 'database.dart';
import 'import_service.dart';

/// File format identifier of a categories export.
const categoriesFormat = 'expense-tracker-categories';

class CategoriesImportResult {
  const CategoriesImportResult({
    this.categories = 0,
    this.renamed = 0,
    this.rules = 0,
    this.merchants = 0,
    this.recategorized = 0,
  });

  final int categories;
  final int renamed;
  final int rules;
  final int merchants;

  /// Existing transactions moved by the imported merchants.
  final int recategorized;
}

/// Shares a category setup between installations (e.g. with a friend):
/// own categories and groups, renamed or archived defaults, and optionally
/// description rules and remembered business merchants. Never exports
/// transactions, amounts, accounts, or merchants that are people.
class CategoriesTransfer {
  CategoriesTransfer(this.db);

  final ExpenseDatabase db;

  Future<Map<String, Object?>> export({bool rules = true, bool merchants = true}) async {
    final defaults = {for (final c in core.defaultCategories) c.id: c};
    final all = await (db.select(db.categories)..orderBy([(c) => OrderingTerm(expression: c.sortOrder)])).get();
    final changed = all.where((c) {
      final d = defaults[c.id];
      return d == null || d.nameFr != c.nameFr || d.nameEn != c.nameEn || c.archived;
    }).toList();
    // A custom category needs its group in the file, even an unchanged default group.
    final needed = {...changed.map((c) => c.id), ...changed.map((c) => c.parentId).whereType<String>()};
    final exported = all.where((c) => needed.contains(c.id)).toList();

    final out = <String, Object?>{
      'format': categoriesFormat,
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'categories': [
        for (final c in exported)
          {
            'id': c.id,
            'parentId': c.parentId,
            'nameFr': c.nameFr,
            'nameEn': c.nameEn,
            'type': c.type,
            'color': c.color,
            'archived': c.archived,
            'custom': !defaults.containsKey(c.id),
          },
      ],
    };
    if (rules) {
      out['rules'] = [
        for (final r in await db.select(db.rules).get())
          {
            'categoryId': r.categoryId,
            'descriptionContains': r.descriptionContains,
            'merchantKey': r.merchantKey,
            'code': r.code,
          },
      ];
    }
    if (merchants) {
      // Remembered merchants, minus people (anyone paid or paying by Interac).
      final rows = await db
          .customSelect(
            'SELECT m.key, m.name, m.category_id FROM merchants m WHERE m.category_id IS NOT NULL '
            'AND NOT EXISTS (SELECT 1 FROM transactions t WHERE t.merchant_id = m.id AND t.is_person) '
            'ORDER BY m.name',
            readsFrom: {db.merchants, db.transactions},
          )
          .get();
      out['merchants'] = [
        for (final r in rows)
          {'key': r.read<String>('key'), 'name': r.read<String>('name'), 'categoryId': r.read<String>('category_id')},
      ];
    }
    return out;
  }

  /// Adds what's missing; never overrides the receiver's own choices
  /// (existing remembered merchants, existing custom category names).
  Future<CategoriesImportResult> import(Map<String, dynamic> json) async {
    if (json['format'] != categoriesFormat) throw const FormatException('Not a categories export');
    final result = await db.transaction(() async {
      var added = 0, renamed = 0, rulesAdded = 0, merchantsAdded = 0;
      final existing = {for (final c in await db.select(db.categories).get()) c.id: c};
      final defaults = {for (final c in core.defaultCategories) c.id: c};
      final count = existing.length;
      final categories = [for (final c in json['categories'] as List? ?? const []) c as Map<String, dynamic>]
        // groups before their categories
        ..sort((a, b) => (a['parentId'] == null ? 0 : 1).compareTo(b['parentId'] == null ? 0 : 1));
      for (final (i, c) in categories.indexed) {
        final id = c['id'] as String;
        final current = existing[id];
        if (current == null) {
          final parent = c['parentId'] as String?;
          if (parent != null && !existing.containsKey(parent) && !categories.any((x) => x['id'] == parent)) continue;
          await db
              .into(db.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: id,
                  parentId: Value(parent),
                  nameFr: c['nameFr'] as String,
                  nameEn: c['nameEn'] as String,
                  type: c['type'] as String? ?? core.CategoryType.expense.name,
                  color: c['color'] as int? ?? 0xFF757575,
                  sortOrder: 1000 + count + i,
                  archived: Value(c['archived'] as bool? ?? false),
                ),
              );
          existing[id] = await (db.select(db.categories)..where((x) => x.id.equals(id))).getSingle();
          added++;
        } else {
          // Rename a default the receiver hasn't renamed themselves.
          final d = defaults[id];
          final untouched = d != null && current.nameFr == d.nameFr && current.nameEn == d.nameEn;
          if (untouched && (c['nameFr'] != d.nameFr || c['nameEn'] != d.nameEn)) {
            await (db.update(db.categories)..where((x) => x.id.equals(id))).write(
              CategoriesCompanion(nameFr: Value(c['nameFr'] as String), nameEn: Value(c['nameEn'] as String)),
            );
            renamed++;
          }
        }
      }

      final known = {for (final c in await db.select(db.categories).get()) c.id};
      final rules = await db.select(db.rules).get();
      for (final r in [for (final r in json['rules'] as List? ?? const []) r as Map<String, dynamic>]) {
        final category = r['categoryId'] as String;
        if (!known.contains(category)) continue;
        final duplicate = rules.any(
          (x) =>
              x.categoryId == category &&
              x.descriptionContains == r['descriptionContains'] &&
              x.merchantKey == r['merchantKey'] &&
              x.code == r['code'],
        );
        if (duplicate) continue;
        await db
            .into(db.rules)
            .insert(
              RulesCompanion.insert(
                categoryId: category,
                descriptionContains: Value(r['descriptionContains'] as String?),
                merchantKey: Value(r['merchantKey'] as String?),
                code: Value(r['code'] as String?),
                createdAt: DateTime.now(),
              ),
            );
        rulesAdded++;
      }

      for (final m in [for (final m in json['merchants'] as List? ?? const []) m as Map<String, dynamic>]) {
        final category = m['categoryId'] as String;
        if (!known.contains(category)) continue;
        final key = m['key'] as String;
        final row = await (db.select(db.merchants)..where((x) => x.key.equals(key))).getSingleOrNull();
        if (row == null) {
          await db
              .into(db.merchants)
              .insert(MerchantsCompanion.insert(key: key, name: m['name'] as String, categoryId: Value(category)));
          merchantsAdded++;
        } else if (row.categoryId == null) {
          await (db.update(
            db.merchants,
          )..where((x) => x.id.equals(row.id))).write(MerchantsCompanion(categoryId: Value(category)));
          merchantsAdded++;
        }
      }
      return CategoriesImportResult(categories: added, renamed: renamed, rules: rulesAdded, merchants: merchantsAdded);
    });
    // Imported merchants and rules apply to lines the app categorized by itself.
    final moved = await ImportService(db).refreshAutomaticCategories();
    return CategoriesImportResult(
      categories: result.categories,
      renamed: result.renamed,
      rules: result.rules,
      merchants: result.merchants,
      recategorized: moved,
    );
  }
}
