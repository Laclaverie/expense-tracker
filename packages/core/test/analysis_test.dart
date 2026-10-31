import 'package:core/core.dart';
import 'package:test/test.dart';

SpendLine line(int y, int m, int d, int cents, String? cat, {String merchant = 'M', bool person = false}) =>
    SpendLine(date: DateTime.utc(y, m, d), cents: cents, categoryId: cat, merchant: merchant, isPerson: person);

void main() {
  final lines = [
    line(2026, 6, 10, 1000, 'food.coffee', merchant: 'Tim'), // previous period
    line(2026, 7, 2, 2000, 'food.coffee', merchant: 'Tim'),
    line(2026, 8, 3, 3000, 'food.groceries', merchant: 'IGA'),
    line(2026, 8, 20, 500, 'food.coffee', merchant: 'Tim'),
    line(2026, 9, 1, 149000, 'housing.rent', merchant: 'Landlord', person: true),
    line(2026, 9, 5, -200, 'food.groceries', merchant: 'IGA'), // refund
  ];
  final from = DateTime.utc(2026, 7), to = DateTime.utc(2026, 10);

  test('focus: a group, a category or uncategorized', () {
    expect([inFocus('food.coffee', 'food'), inFocus('food', 'food'), inFocus('foodie.x', 'food')], [true, true, false]);
    expect([inFocus('food.coffee', 'food.coffee'), inFocus('food.groceries', 'food.coffee')], [true, false]);
    expect([inFocus(null, ''), inFocus('food', '')], [true, false]);
  });

  test('months and previous period', () {
    expect(monthsBetween(from, to).map((m) => m.month), [7, 8, 9]);
    expect(previousPeriod(from, to), (DateTime.utc(2026, 4), from));
    expect(monthsBetween(DateTime.utc(2025, 11), DateTime.utc(2026, 2)).map((m) => m.month), [11, 12, 1]);
  });

  test('breakdown by group: monthly series, totals, previous period, share', () {
    final rows = breakdown(lines, from, to, keyOf: (l) => groupKey(l.categoryId), labelOf: (k) => k);
    expect(rows.map((r) => r.key), ['housing', 'food']);
    final food = rows.last;
    expect(food.monthly, [2000, 3500, -200]);
    expect((food.total, food.previousTotal, food.count), (5300, 1000, 4));
    expect(food.previousCount, 1);
    // Ticket 5300 / 4 = 1325 vs 1000 before.
    expect(food.ticketChange, closeTo(0.325, 1e-9));
    expect(food.change, closeTo(4.3, 1e-9));
    expect(food.averagePerMonth, 1767);
    expect(food.last, DateTime.utc(2026, 9, 5));
    expect(rows.first.shareOf(rows.fold(0, (s, r) => s + r.total)), closeTo(149000 / 154300, 1e-9));
  });

  test('breakdown by merchant skips people when the key is null', () {
    final rows = breakdown(lines, from, to, keyOf: (l) => l.isPerson ? null : l.merchant, labelOf: (k) => k);
    expect(rows.map((r) => (r.key, r.total, r.count, r.averageTicket)), [
      ('IGA', 2800, 2, 1400),
      ('Tim', 2500, 2, 1250),
    ]);
  });

  test('monthly totals and period comparison', () {
    expect(monthlyTotals(lines, from, to), [2000, 3500, 148800]);
    final cmp = comparePeriods(
      lines,
      (DateTime.utc(2026, 9), DateTime.utc(2026, 10)),
      (DateTime.utc(2026, 8), DateTime.utc(2026, 9)),
    );
    expect(cmp, [('housing', 149000, 0), ('food', -200, 3500)]);
  });
}
