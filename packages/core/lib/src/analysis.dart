/// Spending statistics computed from spending lines (split-aware, one scope).
library;

/// One spending line: positive cents = money spent (refunds negative).
class SpendLine {
  const SpendLine({
    required this.date,
    required this.cents,
    this.categoryId,
    this.merchantId,
    this.merchant = '',
    this.isPerson = false,
    this.accountId,
    this.anomalyOk = false,
  });

  final DateTime date;
  final int cents;
  final String? categoryId;
  final int? merchantId;
  final String merchant;

  /// Transfer to or from a person: counted in categories, not in merchants.
  final bool isPerson;

  /// Account the line was paid from (null in tests that don't need it).
  final int? accountId;

  /// Marked normal by the user: never an alert, not in usual amounts.
  final bool anomalyOk;
}

/// First days of the months in `[from, to)`.
List<DateTime> monthsBetween(DateTime from, DateTime to) => [
  for (var m = DateTime.utc(from.year, from.month); m.isBefore(to); m = DateTime.utc(m.year, m.month + 1)) m,
];

/// The period of the same length right before `[from, to)` (in months).
(DateTime, DateTime) previousPeriod(DateTime from, DateTime to) {
  final n = monthsBetween(from, to).length;
  return (DateTime.utc(from.year, from.month - n), from);
}

/// Whether [categoryId] is [focus] or inside it (a group or a category).
/// An empty [focus] means uncategorized.
bool inFocus(String? categoryId, String focus) => focus.isEmpty
    ? categoryId == null || categoryId.isEmpty
    : categoryId == focus || (categoryId?.startsWith('$focus.') ?? false);

/// Group of a category id: `food.coffee` -> `food`; null/'' -> ''.
String groupKey(String? categoryId) => categoryId == null || categoryId.isEmpty ? '' : categoryId.split('.').first;

/// Aggregated figures for one key (group, category or merchant) over a range.
class Breakdown {
  Breakdown(
    this.key,
    this.label,
    this.monthly, {
    this.previousTotal = 0,
    this.count = 0,
    this.previousCount = 0,
    this.last,
  });

  final String key;
  final String label;

  /// Spending per month of the range, oldest first.
  final List<int> monthly;

  /// Spending in the previous period of the same length.
  final int previousTotal;

  /// Number of lines.
  final int count;

  /// Number of lines in the previous period.
  final int previousCount;

  /// Most recent line.
  final DateTime? last;

  int get total => monthly.fold(0, (s, v) => s + v);
  int get averagePerMonth => monthly.isEmpty ? 0 : (total / monthly.length).round();
  int get averageTicket => count == 0 ? 0 : (total / count).round();

  /// Relative change vs the previous period, null when there is nothing to compare.
  double? get change => previousTotal <= 0 ? null : (total - previousTotal) / previousTotal;

  /// Relative change of the average ticket vs the previous period.
  double? get ticketChange {
    if (count == 0 || previousCount == 0 || previousTotal <= 0) return null;
    final before = previousTotal / previousCount;
    return (total / count - before) / before;
  }

  double shareOf(int grandTotal) => grandTotal <= 0 ? 0 : total / grandTotal;
}

/// Spending per key over `[from, to)`, with the previous period for comparison.
/// [lines] must cover both periods. Sorted by total, largest first.
List<Breakdown> breakdown(
  List<SpendLine> lines,
  DateTime from,
  DateTime to, {
  required String? Function(SpendLine) keyOf,
  required String Function(String key) labelOf,
}) {
  final months = monthsBetween(from, to);
  final index = {for (final (i, m) in months.indexed) m: i};
  final (prevFrom, prevTo) = previousPeriod(from, to);
  final monthly = <String, List<int>>{};
  final previous = <String, int>{};
  final counts = <String, int>{};
  final previousCounts = <String, int>{};
  final last = <String, DateTime>{};
  for (final l in lines) {
    final key = keyOf(l);
    if (key == null) continue;
    if (!l.date.isBefore(from) && l.date.isBefore(to)) {
      final series = monthly.putIfAbsent(key, () => List.filled(months.length, 0));
      series[index[DateTime.utc(l.date.year, l.date.month)]!] += l.cents;
      counts.update(key, (n) => n + 1, ifAbsent: () => 1);
      if (last[key] == null || l.date.isAfter(last[key]!)) last[key] = l.date;
    } else if (!l.date.isBefore(prevFrom) && l.date.isBefore(prevTo)) {
      previous.update(key, (v) => v + l.cents, ifAbsent: () => l.cents);
      previousCounts.update(key, (n) => n + 1, ifAbsent: () => 1);
      monthly.putIfAbsent(key, () => List.filled(months.length, 0));
    }
  }
  final rows = [
    for (final MapEntry(key: k, value: series) in monthly.entries)
      Breakdown(
        k,
        labelOf(k),
        series,
        previousTotal: previous[k] ?? 0,
        count: counts[k] ?? 0,
        previousCount: previousCounts[k] ?? 0,
        last: last[k],
      ),
  ]..sort((a, b) => b.total.compareTo(a.total));
  return rows;
}

/// Spending per month over `[from, to)`, oldest first.
List<int> monthlyTotals(List<SpendLine> lines, DateTime from, DateTime to) {
  final months = monthsBetween(from, to);
  final index = {for (final (i, m) in months.indexed) m: i};
  final out = List.filled(months.length, 0);
  for (final l in lines) {
    final i = index[DateTime.utc(l.date.year, l.date.month)];
    if (i != null) out[i] += l.cents;
  }
  return out;
}

/// Comparison of two periods per group (or per [keyOf]): `(key, spentA,
/// spentB)`, sorted by the larger absolute difference.
List<(String, int, int)> comparePeriods(
  List<SpendLine> lines,
  (DateTime, DateTime) a,
  (DateTime, DateTime) b, {
  String Function(SpendLine)? keyOf,
}) {
  bool inRange(DateTime d, (DateTime, DateTime) r) => !d.isBefore(r.$1) && d.isBefore(r.$2);
  final spentA = <String, int>{}, spentB = <String, int>{};
  for (final l in lines) {
    final g = keyOf == null ? groupKey(l.categoryId) : keyOf(l);
    if (inRange(l.date, a)) spentA.update(g, (v) => v + l.cents, ifAbsent: () => l.cents);
    if (inRange(l.date, b)) spentB.update(g, (v) => v + l.cents, ifAbsent: () => l.cents);
  }
  final rows = [
    for (final g in {...spentA.keys, ...spentB.keys}) (g, spentA[g] ?? 0, spentB[g] ?? 0),
  ];
  rows.sort((p, q) => (q.$3 - q.$2).abs().compareTo((p.$3 - p.$2).abs()));
  return rows;
}
