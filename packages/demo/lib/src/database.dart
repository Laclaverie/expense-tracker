import 'package:banks/banks.dart';
import 'package:drift/drift.dart';
import 'package:storage/storage.dart';

import 'couple.dart';
import 'desjardins/statements.dart';
import 'household.dart';
import 'life.dart';
import 'persona.dart';

/// The couple's account statement left out of the demo database, so the
/// coverage notices ("relevé manquant") have something to show.
final DateTime missingAccountStatement = couple.show.missingAccountStatement!;

/// Reviewed until this date; later lines wait in "À vérifier", as after a
/// fresh import.
final DateTime reviewedUntil = DateTime.utc(lifeEnd.year, lifeEnd.month, lifeEnd.day - 25);

/// The day the demo databases are imported on: two days after the last card statement.
DateTime get importDay => DateTime.utc(lifeEnd.year, lifeEnd.month, lifeEnd.day + 2);

/// Fills [db] (empty) with the statements of [life] (the couple by default)
/// through the real import, then does what its owner would have done:
/// categories for every merchant up to [reviewedUntil], and its targets.
Future<void> fillDemoDatabase(ExpenseDatabase db, {Life? life}) async {
  life ??= liveHousehold();
  await importAndReview(db, life, desjardinsStatements(life), reviewedUntil);
}

/// Imports [statements] of [life] into [db] (skipping its persona's missing
/// statement), confirms a category for every merchant seen up to [until]
/// (except those left to review) and saves its targets.
Future<void> importAndReview(ExpenseDatabase db, Life life, List<SyntheticStatement> statements, DateTime until) async {
  final show = life.persona.show;
  final importer = ImportService(db, clock: () => importDay);
  for (final s in statements) {
    if (s.closing == show.missingAccountStatement && s.name.contains('account')) continue;
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
      if (e.category != null && !show.leftToReview.contains(e.merchant)) e.merchant: e.category!,
    ...life.accountCategories,
  };
  for (final MapEntry(key: text, value: category) in categories.entries) {
    final first =
        await (db.select(db.transactions)
              ..where((t) => t.description.contains(text) & t.date.isSmallerOrEqualValue(until))
              ..limit(1))
            .getSingleOrNull();
    if (first != null) await repo.setCategory(first.id, category, rememberForMerchant: true);
  }
  final reviewed = await (db.select(
    db.transactions,
  )..where((t) => t.needsReview & t.date.isSmallerOrEqualValue(until))).map((t) => t.id).get();
  await repo.confirmMany(reviewed);

  const scope = Scope('desjardins', currency: 'CAD');
  for (final (category, period, cents) in show.targets) {
    await repo.saveTarget(scope, category, period, cents);
  }
}
