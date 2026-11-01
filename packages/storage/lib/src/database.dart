import 'package:core/core.dart' as core;
import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Accounts, Statements, Categories, Merchants, Rules, Transactions, Splits, Targets])
class ExpenseDatabase extends _$ExpenseDatabase {
  ExpenseDatabase(super.executor);

  /// Read before opening a file, to copy it when this version will migrate it.
  static const currentSchemaVersion = 9;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(splits);
        await m.createTable(targets);
      }
      if (from < 3) {
        await m.addColumn(transactions, transactions.isPerson);
        // Desjardins Interac transfers (VMW) are person to person.
        await customStatement("UPDATE transactions SET is_person = 1 WHERE code = 'VMW'");
      }
      if (from < 4) {
        await m.addColumn(categories, categories.archived);
        // Renamed default, now that Sport is its own group (kept if the user renamed it).
        await customStatement(
          "UPDATE categories SET name_fr = 'Clubs et associations', name_en = 'Clubs & associations' "
          "WHERE id = 'leisure.clubs' AND name_fr = 'Clubs et sports'",
        );
        await seedCategories(); // new defaults must exist before moving references to them
        for (final MapEntry(key: old, value: replacement) in core.retiredCategories.entries) {
          await moveCategoryReferences(old, replacement);
          await (update(
            categories,
          )..where((c) => c.id.equals(old))).write(const CategoriesCompanion(archived: Value(true)));
        }
      }
      if (from < 5) await reclassifyOlderDesjardinsCodes();
      if (from < 6) {
        await m.addColumn(statements, statements.coversSincePrevious);
        // Was implied by the format name before bank plug-ins.
        await customStatement("UPDATE statements SET covers_since_previous = 1 WHERE format = 'desjardins-card'");
        // Bank scopes now carry their currency (a bank may hold accounts in several).
        await customStatement(
          "UPDATE targets SET scope = scope || '-' || COALESCE((SELECT a.currency FROM accounts a "
          "WHERE a.institution = targets.scope LIMIT 1), 'CAD') WHERE scope NOT LIKE '%-%'",
        );
      }
      if (from < 7) await m.addColumn(transactions, transactions.anomalyOk);
      if (from < 8) {
        // Every statement imported so far came from a PDF and passed its checks.
        await m.addColumn(statements, statements.fileType);
        await m.addColumn(statements, statements.verified);
      }
      if (from < 9) await m.addColumn(categories, categories.excludedFromShare);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // Adds default categories introduced by app updates; keeps user edits.
      if (!details.wasCreated) await seedCategories();
    },
  );

  /// Codes of older Desjardins account statements (2021–2024) that were
  /// imported as plain expenses / refunds: a mobile deposit lowered spending,
  /// an ATM withdrawal counted as spending. Same mapping as the importer now
  /// uses (`import_desjardins/to_core.dart`). Kinds the user changed are kept;
  /// categories only replace automatic ones.
  Future<void> reclassifyOlderDesjardinsCodes() async {
    const fixes = {
      'VIM': ('transfer', 'excluded.internal_transfer'),
      'VIR': ('transfer', 'excluded.internal_transfer'),
      'OUV': ('transfer', 'excluded.internal_transfer'),
      'IDGA': ('transfer', 'excluded.internal_transfer'),
      'RGA': ('transfer', 'excluded.cash_withdrawal'),
      'RGP': ('transfer', 'excluded.cash_withdrawal'),
      'ADM': ('fee', 'finance.bank_fees'),
      'INT': ('interest', 'income.interest'),
      'BNI': ('interest', 'income.interest'),
      'DMD': ('income', 'income.other'),
      'RIS': ('income', 'income.other'),
      'IVMW': ('income', 'income.reimbursements'),
    };
    const automatic = "('seed', 'keyword', 'hint', 'none')";
    for (final MapEntry(key: code, value: (kind, category)) in fixes.entries) {
      await customStatement(
        'UPDATE transactions SET kind = ?, '
        'category_id = CASE WHEN confidence IN $automatic THEN ? ELSE category_id END, '
        "needs_review = CASE WHEN confidence IN $automatic THEN 0 ELSE needs_review END, "
        "confidence = CASE WHEN confidence IN $automatic THEN 'bank' ELSE confidence END "
        "WHERE code = ? AND kind IN ('expense', 'refund') AND source = 'statement' AND account_id IN "
        "(SELECT id FROM accounts WHERE institution = 'desjardins' AND type != 'creditCard')",
        [kind, category, code],
      );
    }
    await customStatement("UPDATE transactions SET is_person = 1 WHERE code = 'IVMW'");
    // ATM withdrawals now credit the cash wallet, like at import.
    const pending =
        "code IN ('RGA', 'RGP') AND kind = 'transfer' AND transfer_group IS NULL AND account_id IN "
        "(SELECT id FROM accounts WHERE institution = 'desjardins')";
    final count = await customSelect('SELECT COUNT(*) AS n FROM transactions WHERE $pending').getSingle();
    if (count.read<int>('n') == 0) return;
    await customStatement(
      'INSERT INTO accounts (institution, ref, name, type, currency) '
      "SELECT 'cash', 'cash-CAD', 'Cash CAD', 'cash', 'CAD' "
      "WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE institution = 'cash' AND ref = 'cash-CAD')",
    );
    await customStatement('UPDATE transactions SET transfer_group = lower(hex(randomblob(16))) WHERE $pending');
    await customStatement(
      'INSERT INTO transactions (id, account_id, date, amount, description, code, kind, category_id, confidence, '
      'needs_review, source, statement_id, fingerprint, transfer_group, created_at, updated_at) '
      "SELECT lower(hex(randomblob(16))), (SELECT id FROM accounts WHERE institution = 'cash' AND ref = 'cash-CAD'), "
      "date, -amount, description, code, 'transfer', 'excluded.cash_withdrawal', 'bank', 0, 'statement', "
      "statement_id, fingerprint || '-cash', transfer_group, created_at, updated_at FROM transactions "
      "WHERE code IN ('RGA', 'RGP') AND kind = 'transfer' AND transfer_group IS NOT NULL AND account_id IN "
      "(SELECT id FROM accounts WHERE institution = 'desjardins') "
      'AND transfer_group NOT IN (SELECT transfer_group FROM transactions t2 WHERE t2.account_id IN '
      "(SELECT id FROM accounts WHERE institution = 'cash') AND t2.transfer_group IS NOT NULL)",
    );
  }

  /// Inserts default categories that don't exist yet and keeps defaults in
  /// display order. Names chosen by the user are kept.
  Future<void> seedCategories() => batch((b) {
    for (final (i, c) in core.defaultCategories.indexed) {
      b.insert(
        categories,
        CategoriesCompanion.insert(
          id: c.id,
          parentId: Value(c.parentId),
          nameFr: c.nameFr,
          nameEn: c.nameEn,
          type: c.type.name,
          color: c.color,
          sortOrder: i,
        ),
        mode: InsertMode.insertOrIgnore,
      );
      b.update(categories, CategoriesCompanion(sortOrder: Value(i)), where: (t) => t.id.equals(c.id));
    }
  });

  /// Points everything that used category [from] at [to] (null: clears it).
  Future<void> moveCategoryReferences(String from, String? to) async {
    final v = [Variable.withString(from)];
    final target = to == null ? 'NULL' : "'${to.replaceAll("'", "''")}'";
    await customUpdate(
      'UPDATE transactions SET category_id = $target WHERE category_id = ?',
      variables: v,
      updates: {transactions},
    );
    await customUpdate(
      'UPDATE merchants SET category_id = $target WHERE category_id = ?',
      variables: v,
      updates: {merchants},
    );
    if (to == null) {
      await customUpdate('DELETE FROM splits WHERE category_id = ?', variables: v, updates: {splits});
      await customUpdate('DELETE FROM rules WHERE category_id = ?', variables: v, updates: {rules});
      await customUpdate('DELETE FROM targets WHERE category_id = ?', variables: v, updates: {targets});
    } else {
      await customUpdate(
        'UPDATE splits SET category_id = $target WHERE category_id = ?',
        variables: v,
        updates: {splits},
      );
      await customUpdate(
        'UPDATE rules SET category_id = $target WHERE category_id = ?',
        variables: v,
        updates: {rules},
      );
      await customUpdate(
        'UPDATE targets SET category_id = $target WHERE category_id = ?',
        variables: v,
        updates: {targets},
      );
    }
  }
}
