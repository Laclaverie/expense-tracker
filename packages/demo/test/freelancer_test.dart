import 'package:core/core.dart';
import 'package:demo/demo.dart';
import 'package:demo/src/database.dart';
import 'package:drift/native.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

/// The freelancer shows what the couple can't: uneven income, quarterly
/// taxes, one card and no TFSA.
void main() {
  final life = liveHousehold(persona: freelancer);

  int incomeIn(int year, int month) => life.accountEntries
      .where((e) => e.code == 'DI' && e.date.year == year && e.date.month == month)
      .fold(0, (s, e) => s + e.amount);

  test('uneven income: a dry month and a month about three times the usual', () {
    final months = [
      for (
        var m = DateTime.utc(lifeStart.year, lifeStart.month + 1);
        m.isBefore(DateTime.utc(2026, 10));
        m = DateTime.utc(m.year, m.month + 1)
      )
        incomeIn(m.year, m.month),
    ]..sort();
    final median = months[months.length ~/ 2];
    expect(median, greaterThan(0));
    expect(incomeIn(2025, 8), 0);
    expect(incomeIn(2026, 3), greaterThanOrEqualTo(3 * median));
  });

  test('one card, no TFSA', () {
    expect(life.cardEntries.map((e) => e.card).toSet(), {'0033', '0003'});
    expect(life.accountEntries.where((e) => e.account == 'ET 2'), isEmpty);
  });

  test('the same seed lives the same life', () {
    final again = liveHousehold(persona: freelancer);
    expect(
      again.accountEntries.map((e) => '${e.date} ${e.description} ${e.amount}'),
      life.accountEntries.map((e) => '${e.date} ${e.description} ${e.amount}'),
    );
  });

  test('quarterly taxes found as recurring payments', () async {
    final db = ExpenseDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await fillDemoDatabase(db, life: life);
    final lines = await ExpenseRepository(db)
        .watchSpendingDetail(const Scope('desjardins', currency: 'CAD'), DateTime.utc(2000), DateTime.utc(2100))
        .first;
    final found = {for (final r in detectRecurring(lines)) r.merchant: r.cadence};
    expect(found['Revenu Québec'], Cadence.quarterly);
    expect(found['Revenu Canada'], Cadence.quarterly);
  });
}
