import 'package:banks/banks.dart';
import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:storage/storage.dart';

import 'desjardins/statements.dart';
import 'household.dart';
import 'life.dart';
import 'persona.dart';

/// Account statement left out of the demo database, so the coverage notices
/// ("relevé manquant") have something to show.
final DateTime missingAccountStatement = DateTime.utc(2026, 6, 30);

/// Reviewed until this date; later lines wait in "À vérifier", as after a
/// fresh import.
final DateTime reviewedUntil = DateTime.utc(lifeEnd.year, lifeEnd.month, lifeEnd.day - 25);

/// Merchants the household never categorized: they stay to review.
const _leftToReview = {'LIBRAIRIE DU PLATEAU', 'CINEMA DU QUARTIER'};

/// Fills [db] (empty) with the household's statements through the real
/// import, then does what its owner would have done: categories for every
/// merchant up to [reviewedUntil], and a few monthly targets.
Future<void> fillDemoDatabase(ExpenseDatabase db, {Life? life}) async {
  life ??= liveHousehold();
  final importer = ImportService(db, clock: () => DateTime.utc(lifeEnd.year, lifeEnd.month, lifeEnd.day + 2));
  for (final s in desjardinsStatements(life)) {
    if (s.closing == missingAccountStatement && s.name.contains('account')) continue;
    final result = await importer.importStatement(
      readStatement(PdfInput('${s.name}.pdf', s.words)),
      fileHash: s.name,
      fileName: '${s.name}.pdf',
    );
    if (result.status != ImportStatus.imported) throw StateError('${s.name}: ${result.status}');
  }
  await importer.refreshAutomaticCategories();

  final repo = ExpenseRepository(db);
  final categories = <String, String>{
    for (final e in life.cardEntries)
      if (e.category != null && !_leftToReview.contains(e.merchant)) e.merchant: e.category!,
    ...life.accountCategories,
  };
  for (final MapEntry(key: text, value: category) in categories.entries) {
    final first =
        await (db.select(db.transactions)
              ..where((t) => t.description.contains(text) & t.date.isSmallerOrEqualValue(reviewedUntil))
              ..limit(1))
            .getSingleOrNull();
    if (first != null) await repo.setCategory(first.id, category, rememberForMerchant: true);
  }
  final reviewed = await (db.select(
    db.transactions,
  )..where((t) => t.needsReview & t.date.isSmallerOrEqualValue(reviewedUntil))).map((t) => t.id).get();
  await repo.confirmMany(reviewed);

  const scope = Scope('desjardins', currency: 'CAD');
  await repo.saveTarget(scope, 'food.groceries', TargetPeriod.month, 85000);
  await repo.saveTarget(scope, 'food.restaurants', TargetPeriod.month, 25000);
  await repo.saveTarget(scope, null, TargetPeriod.month, 400000);
}
