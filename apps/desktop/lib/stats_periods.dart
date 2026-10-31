/// Which months the Statistics page analyzes. Kept out of the widgets so the
/// rules have unit tests (`test/stats_periods_test.dart`).
library;

import 'package:core/core.dart' show DayRange;

enum StatsRange { six, twelve, thisYear, lastYear, all }

/// `[from, to)` for [range], ending with the month of [anchor] (the latest
/// month with data — never the month picked on the dashboard).
(DateTime, DateTime) statsPeriod(StatsRange range, DateTime anchor) {
  final end = DateTime.utc(anchor.year, anchor.month + 1);
  return switch (range) {
    StatsRange.six => (DateTime.utc(anchor.year, anchor.month - 5), end),
    StatsRange.twelve => (DateTime.utc(anchor.year, anchor.month - 11), end),
    StatsRange.thisYear => (DateTime.utc(anchor.year), end),
    StatsRange.lastYear => (DateTime.utc(anchor.year - 1), DateTime.utc(anchor.year)),
    StatsRange.all => (DateTime.utc(2000), end),
  };
}

/// [from], moved to the month of the earliest of [dates] when the data starts
/// inside the range: months before the first statement would count as 0 $
/// and skew averages.
DateTime dataStart(DateTime from, DateTime to, Iterable<DateTime> dates) {
  if (dates.isEmpty) return from;
  final first = dates.reduce((a, b) => a.isBefore(b) ? a : b);
  final month = DateTime.utc(first.year, first.month);
  return month.isAfter(from) && month.isBefore(to) ? month : from;
}

/// All accounts together are analyzed only from the first month every
/// statement format exists (before the first card statement, card spending
/// would be missing). Returns the start and the format that moved it, if any.
/// Only applies with several formats and no single account selected.
(DateTime, String?) commonStart(
  Map<String, List<DayRange>> coverage,
  DateTime from,
  DateTime to, {
  required bool allAccounts,
}) {
  var start = from;
  String? limitedBy;
  if (!allAccounts || coverage.length < 2) return (start, null);
  for (final MapEntry(key: format, value: ranges) in coverage.entries) {
    if (ranges.isEmpty) continue;
    final first = ranges.map((r) => r.$1).reduce((a, b) => a.isBefore(b) ? a : b);
    final month = DateTime.utc(first.year, first.month);
    if (month.isAfter(start) && month.isBefore(to)) (start, limitedBy) = (month, format);
  }
  return (start, limitedBy);
}
