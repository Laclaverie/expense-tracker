/// Which days imported statements cover, so months missing a statement are
/// not mistaken for months without spending.
library;

/// Inclusive range of calendar days (UTC dates).
typedef DayRange = (DateTime, DateTime);

/// Card statements state only their closing date: each one covers the days
/// since the previous closing date (or ~30 days when there is no previous
/// statement within 40 days).
List<DayRange> cardRanges(Iterable<DateTime> closingDates) {
  final sorted = closingDates.toList()..sort();
  return [
    for (final (i, d) in sorted.indexed)
      (
        i > 0 && d.difference(sorted[i - 1]).inDays <= 40
            ? sorted[i - 1].add(const Duration(days: 1))
            : d.subtract(const Duration(days: 30)),
        d,
      ),
  ];
}

/// Coverage of one month by one statement type.
class MonthCoverage {
  const MonthCoverage(this.coveredDays, this.daysInMonth, this.coveredUntil);

  final int coveredDays;
  final int daysInMonth;

  /// Last day of the run of covered days starting on the 1st (null if the 1st
  /// isn't covered).
  final DateTime? coveredUntil;

  bool get full => coveredDays == daysInMonth;
  bool get none => coveredDays == 0;
}

MonthCoverage monthCoverage(List<DayRange> ranges, DateTime month) {
  final first = DateTime.utc(month.year, month.month);
  final next = DateTime.utc(month.year, month.month + 1);
  final days = next.difference(first).inDays;
  var covered = 0;
  DateTime? until;
  var run = true;
  for (var i = 0; i < days; i++) {
    final day = first.add(Duration(days: i));
    final inside = ranges.any((r) => !day.isBefore(r.$1) && !day.isAfter(r.$2));
    if (inside) {
      covered++;
      if (run) until = day;
    } else {
      run = false;
    }
  }
  return MonthCoverage(covered, days, until);
}

/// Average of [values] over the months flagged complete in [complete]
/// (all months when none are flagged).
int averageOverComplete(List<int> values, List<bool> complete) {
  final picked = [
    for (final (i, v) in values.indexed)
      if (complete[i]) v,
  ];
  final use = picked.isEmpty ? values : picked;
  return use.isEmpty ? 0 : (use.fold(0, (s, v) => s + v) / use.length).round();
}

/// Share of income kept: (income − spending) / income, over the months
/// flagged complete in [complete] (all months when none are flagged; a month
/// missing a statement would look thrifty). Negative when spending is higher.
/// Null without income (a card alone, a savings account fed by transfers).
double? savingsRate(List<int> income, List<int> spending, List<bool> complete) {
  final pick = complete.contains(true) ? complete : [for (final _ in complete) true];
  var inc = 0, out = 0;
  for (var i = 0; i < pick.length; i++) {
    if (!pick[i]) continue;
    inc += income[i];
    out += spending[i];
  }
  return inc <= 0 ? null : (inc - out) / inc;
}
