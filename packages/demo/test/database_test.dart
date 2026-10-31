import 'package:core/core.dart';
import 'package:demo/src/database.dart';
import 'package:drift/native.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

/// The demo database shows what the app can do: these are the features it
/// must have something for, not exact values.
void main() {
  late ExpenseDatabase db;
  late ExpenseRepository repo;
  const scope = Scope('desjardins', currency: 'CAD');

  setUpAll(() async {
    db = ExpenseDatabase(NativeDatabase.memory());
    await fillDemoDatabase(db);
    repo = ExpenseRepository(db);
  });
  tearDownAll(() => db.close());

  Future<List<SpendLine>> lines() => repo.watchSpendingDetail(scope, DateTime.utc(2000), DateTime.utc(2100)).first;

  test('accounts: checking, savings, TFSA, member share, card', () async {
    final accounts = await repo.watchAccounts().first;
    expect(
      accounts.map((a) => a.type).toSet(),
      containsAll([
        for (final t in [AccountType.checking, AccountType.savings, AccountType.registered, AccountType.creditCard])
          t.name,
      ]),
    );
  });

  test('recurring payments, one with a price change, one stopped', () async {
    final found = detectRecurring(await lines());
    final names = {for (final r in found) r.merchant: r};
    expect(names.keys, containsAll(['Netflix', 'Spotify', 'Virgin Plus']));
    expect(names['Netflix']!.maxAmount, greaterThan(names['Netflix']!.minAmount));
    expect(found.where((r) => !r.active).map((r) => r.merchant), contains('Club Sportif Boreal'));
    expect(found.where((r) => r.isPerson), isNotEmpty, reason: 'rent to a person');
  });

  test('alerts: a very large expense and a bill at a different amount', () async {
    final kinds = {for (final a in detectAnomalies(await lines())) a.kind};
    expect(kinds, containsAll([AnomalyKind.highAmount, AnomalyKind.regularAmount]));
  });

  test('older lines reviewed, the latest weeks still to review', () async {
    final pending = await (db.select(db.transactions)..where((t) => t.needsReview)).get();
    expect(pending, isNotEmpty);
    expect(pending.every((t) => t.date.isAfter(reviewedUntil) || t.categoryId == null), isTrue);
    final uncategorized = await (db.select(db.transactions)..where((t) => t.categoryId.isNull())).get();
    expect(uncategorized.length, lessThan(40));
  });

  test('a foreign trip, transfers paired, a missing statement', () async {
    expect(await (db.select(db.transactions)..where((t) => t.foreignCurrency.equals('USD'))).get(), isNotEmpty);
    final statements = await repo.watchStatements().first;
    expect(
      statements.where((s) => s.periodEnd == missingAccountStatement && s.format == 'desjardins-account'),
      isEmpty,
    );
    final transfers = await (db.select(db.transactions)..where((t) => t.transferGroup.isNotNull())).get();
    expect(transfers, isNotEmpty);
  });
}
