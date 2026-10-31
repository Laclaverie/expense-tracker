import 'package:core/core.dart' show DayRange;
import 'package:expense_desktop/stats_periods.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime m(int y, int mo, [int d = 1]) => DateTime.utc(y, mo, d);

void main() {
  final anchor = m(2026, 9); // latest month with data

  test('ranges end with the latest month with data, whatever month the dashboard shows', () {
    expect(statsPeriod(StatsRange.thisYear, anchor), (m(2026, 1), m(2026, 10))); // not Jan–May
    expect(statsPeriod(StatsRange.lastYear, anchor), (m(2025, 1), m(2026, 1)));
    expect(statsPeriod(StatsRange.six, anchor), (m(2026, 4), m(2026, 10)));
    expect(statsPeriod(StatsRange.twelve, anchor), (m(2025, 10), m(2026, 10)));
    expect(statsPeriod(StatsRange.all, anchor).$2, m(2026, 10));
    expect(statsPeriod(StatsRange.twelve, m(2026, 1)), (m(2025, 2), m(2026, 2)));
  });

  test('a range starting before the first data starts with the data', () {
    final (from, to) = statsPeriod(StatsRange.all, anchor);
    expect(dataStart(from, to, [m(2021, 9, 3), m(2024, 1, 2)]), m(2021, 9));
    expect(dataStart(m(2026, 1), m(2026, 10), [m(2021, 9, 3)]), m(2026, 1)); // data older: unchanged
    expect(dataStart(m(2026, 1), m(2026, 10), const []), m(2026, 1));
  });

  final coverage = <String, List<DayRange>>{
    'desjardins-account': [(m(2021, 9), m(2021, 9, 30)), (m(2026, 9), m(2026, 9, 30))],
    'desjardins-card': [(m(2025, 12, 21), m(2026, 1, 20))],
  };

  test('all accounts together start when every statement type exists', () {
    expect(commonStart(coverage, m(2021, 9), m(2026, 10), allAccounts: true), (m(2025, 12), 'desjardins-card'));
    // Range already after the card's start: nothing to limit.
    expect(commonStart(coverage, m(2026, 1), m(2026, 10), allAccounts: true), (m(2026, 1), null));
  });

  test('one account, or a single statement type, keeps the whole history', () {
    expect(commonStart(coverage, m(2021, 9), m(2026, 10), allAccounts: false), (m(2021, 9), null));
    expect(
      commonStart({'desjardins-account': coverage['desjardins-account']!}, m(2021, 9), m(2026, 10), allAccounts: true),
      (m(2021, 9), null),
    );
  });
}
