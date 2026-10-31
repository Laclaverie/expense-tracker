import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('periods: weeks start Monday, months and years', () {
    final thu = DateTime.utc(2026, 10, 15);
    expect(periodRange(TargetPeriod.week, thu), (DateTime.utc(2026, 10, 12), DateTime.utc(2026, 10, 19)));
    expect(periodRange(TargetPeriod.week, DateTime.utc(2026, 10, 12)).$1, DateTime.utc(2026, 10, 12));
    expect(periodRange(TargetPeriod.week, DateTime.utc(2026, 10, 18)).$1, DateTime.utc(2026, 10, 12));
    expect(periodRange(TargetPeriod.month, thu), (DateTime.utc(2026, 10), DateTime.utc(2026, 11)));
    expect(periodRange(TargetPeriod.year, thu), (DateTime.utc(2026), DateTime.utc(2027)));
    expect(previousPeriods(TargetPeriod.month, thu, 3).map((p) => p.$1.month), [9, 8, 7]);
    expect(previousPeriods(TargetPeriod.month, DateTime.utc(2026, 1, 5), 1).single.$1, DateTime.utc(2025, 12));
  });

  test('targetCovers: total, group, category', () {
    expect(targetCovers(null, 'food.coffee'), isTrue);
    expect(targetCovers('food', 'food.coffee'), isTrue);
    expect(targetCovers('food', 'foodtruck'), isFalse);
    expect(targetCovers('food.coffee', 'food.coffee'), isTrue);
    expect(targetCovers('food.coffee', 'food.bars'), isFalse);
    expect(targetCovers('food', null), isFalse);
  });

  test('progress projects the current pace', () {
    final (start, end) = periodRange(TargetPeriod.month, DateTime.utc(2026, 9, 1));
    // 10 days of 30 elapsed, 100 $ spent -> 300 $ projected
    final p = progress(target: 25000, spent: 10000, start: start, end: end, today: DateTime.utc(2026, 9, 10));
    expect((p.projected, p.status), (30000, TargetStatus.atRisk));
    expect(
      progress(target: 40000, spent: 10000, start: start, end: end, today: DateTime.utc(2026, 9, 10)).status,
      TargetStatus.onTrack,
    );
    expect(
      progress(target: 5000, spent: 10000, start: start, end: end, today: DateTime.utc(2026, 9, 10)).status,
      TargetStatus.over,
    );
    // finished period: projection = spent
    final done = progress(target: 25000, spent: 20000, start: start, end: end, today: DateTime.utc(2026, 11, 2));
    expect((done.projected, done.status), (20000, TargetStatus.onTrack));
  });

  test('suggestTarget rounds the average up to 10', () {
    expect(suggestTarget([21000, 25000, 30500]), 26000);
    expect(suggestTarget([]), 0);
  });
}
