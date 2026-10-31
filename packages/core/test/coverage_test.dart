import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  final d = DateTime.utc;

  test('card statements cover the days since the previous closing date', () {
    final ranges = cardRanges([d(2026, 9, 18), d(2026, 8, 19), d(2026, 1, 20)]);
    expect(ranges, [
      (d(2025, 12, 21), d(2026, 1, 20)), // no previous within 40 days: ~30 days
      (d(2026, 7, 20), d(2026, 8, 19)),
      (d(2026, 8, 20), d(2026, 9, 18)),
    ]);
  });

  test('month coverage: full, partial with covered-until, none', () {
    final ranges = [(d(2026, 7, 20), d(2026, 8, 19)), (d(2026, 8, 20), d(2026, 9, 18))];
    expect(monthCoverage(ranges, d(2026, 8)).full, isTrue);
    final sept = monthCoverage(ranges, d(2026, 9));
    expect((sept.full, sept.none, sept.coveredUntil), (false, false, d(2026, 9, 18)));
    expect(monthCoverage(ranges, d(2026, 6)).none, isTrue);
    final account = [(d(2026, 4, 1), d(2026, 4, 30))];
    expect(monthCoverage(account, d(2026, 4)).full, isTrue);
  });

  test('averages use complete months only', () {
    expect(averageOverComplete([100, 0, 300, 50], [true, false, true, false]), 200);
    expect(averageOverComplete([100, 300], [false, false]), 200);
    expect(averageOverComplete([], []), 0);
  });

  test('savings rate over complete months, null without income', () {
    expect(savingsRate([1000, 1000, 1000], [600, 0, 900], [true, false, true]), closeTo(0.25, 1e-9));
    expect(savingsRate([1000], [1500], [false]), closeTo(-0.5, 1e-9));
    expect(savingsRate([0, 0], [100, 100], [true, true]), isNull);
    expect(savingsRate([], [], []), isNull);
  });
}
