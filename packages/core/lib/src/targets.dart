/// Spending targets: a limit per week, month or year, for one category, one
/// group, or all spending. Analysis only — nothing is blocked or moved.
enum TargetPeriod { week, month, year }

enum TargetStatus {
  /// Spent and projected end-of-period spending are within the target.
  onTrack,

  /// Within the target so far, but the current pace ends above it.
  atRisk,

  /// Already above the target.
  over,
}

/// `[start, end)` of the period containing [date] (UTC calendar dates).
/// Weeks start on Monday.
(DateTime, DateTime) periodRange(TargetPeriod period, DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  return switch (period) {
    TargetPeriod.week => () {
      final start = d.subtract(Duration(days: d.weekday - DateTime.monday));
      return (start, start.add(const Duration(days: 7)));
    }(),
    TargetPeriod.month => (DateTime.utc(d.year, d.month), DateTime.utc(d.year, d.month + 1)),
    TargetPeriod.year => (DateTime.utc(d.year), DateTime.utc(d.year + 1)),
  };
}

/// The [count] periods before the one containing [date], most recent first.
List<(DateTime, DateTime)> previousPeriods(TargetPeriod period, DateTime date, int count) {
  final out = <(DateTime, DateTime)>[];
  var (start, _) = periodRange(period, date);
  for (var i = 0; i < count; i++) {
    final previous = periodRange(period, start.subtract(const Duration(days: 1)));
    out.add(previous);
    start = previous.$1;
  }
  return out;
}

/// Whether a spending line counts towards a target on [categoryId]:
/// null = all spending, a group id = its categories, otherwise exact match.
bool targetCovers(String? targetCategory, String? lineCategory) {
  if (targetCategory == null) return true;
  if (lineCategory == null) return false;
  return lineCategory == targetCategory || lineCategory.startsWith('$targetCategory.');
}

class TargetProgress {
  const TargetProgress({required this.target, required this.spent, required this.projected, required this.status});

  /// Cents.
  final int target;
  final int spent;

  /// End-of-period spending at the current pace (cents).
  final int projected;
  final TargetStatus status;

  double get ratio => target <= 0 ? 0 : spent / target;
}

/// Progress of the period `[start, end)` on [today]. A period already over
/// projects to what was spent.
TargetProgress progress({
  required int target,
  required int spent,
  required DateTime start,
  required DateTime end,
  required DateTime today,
}) {
  final day = DateTime.utc(today.year, today.month, today.day);
  final total = end.difference(start).inDays;
  final elapsed = (day.difference(start).inDays + 1).clamp(1, total);
  final projected = day.isBefore(end) ? (spent * total / elapsed).round() : spent;
  final status = spent > target
      ? TargetStatus.over
      : projected > target
      ? TargetStatus.atRisk
      : TargetStatus.onTrack;
  return TargetProgress(target: target, spent: spent, projected: projected, status: status);
}

/// Suggested target: average of the given past periods' spending, rounded up
/// to a whole 10 (in currency units).
int suggestTarget(List<int> pastSpending) {
  if (pastSpending.isEmpty) return 0;
  final average = pastSpending.fold(0, (s, v) => s + v) / pastSpending.length;
  return ((average / 1000).ceil() * 1000).clamp(0, 1 << 50);
}
