/// What the statistics and targets screens compute from the repository's
/// rows, without any UI type (shared by the desktop and phone apps).
library;

import 'package:core/core.dart';

import 'database.dart';
import 'repository.dart';

/// A month and the statement types that don't fully cover it.
class MonthStatus {
  const MonthStatus(this.month, this.gaps);

  final DateTime month;
  final List<(String, MonthCoverage)> gaps;

  bool get complete => gaps.isEmpty;
}

/// Status of each month for every statement type ever imported in the scope.
/// A scope without statements (cash wallet) is always complete.
List<MonthStatus> monthStatuses(Map<String, List<DayRange>> coverage, List<DateTime> months) => [
  for (final m in months)
    MonthStatus(m, [
      for (final MapEntry(key: format, value: ranges) in coverage.entries)
        if (!monthCoverage(ranges, m).full) (format, monthCoverage(ranges, m)),
    ]),
];

/// Currency of a scope's amounts. Scopes from `watchScopes` always carry it.
String scopeCurrency(Scope scope) => scope.currency ?? 'CAD';

/// A target with its progress for the period containing the reference date,
/// and whether past periods stayed within it.
class TargetView {
  const TargetView(this.row, this.period, this.start, this.end, this.progress, this.history);

  final TargetRow row;
  final TargetPeriod period;
  final DateTime start;
  final DateTime end;
  final TargetProgress progress;

  /// Past periods, most recent first: `(start, end, spent)`.
  final List<(DateTime, DateTime, int)> history;
}

/// How many past periods the history shows.
const historyLength = {TargetPeriod.week: 8, TargetPeriod.month: 6, TargetPeriod.year: 3};

/// Spending lines needed for targets around [reference]: three years back.
(DateTime, DateTime) linesWindow(DateTime reference) =>
    (DateTime.utc(reference.year - 3), DateTime.utc(reference.year + 1, 1, 8));

int spentIn(List<(DateTime, String?, int)> lines, String? categoryId, DateTime start, DateTime end) => lines
    .where((l) => !l.$1.isBefore(start) && l.$1.isBefore(end) && targetCovers(categoryId, l.$2))
    .fold(0, (s, l) => s + l.$3);

/// [reference]: the day whose periods are shown. [today] decides whether the
/// period is still running (projection) or over.
List<TargetView> computeTargets(
  List<TargetRow> targets,
  List<(DateTime, String?, int)> lines,
  DateTime reference,
  DateTime today,
) {
  today = DateTime.utc(today.year, today.month, today.day);
  final views = [
    for (final t in targets)
      () {
        final period = TargetPeriod.values.byName(t.period);
        final (start, end) = periodRange(period, reference);
        final spent = spentIn(lines, t.categoryId, start, end);
        final asOf = today.isBefore(end) ? today : end;
        return TargetView(
          t,
          period,
          start,
          end,
          progress(target: t.amount, spent: spent, start: start, end: end, today: asOf),
          [
            for (final (s, e) in previousPeriods(period, reference, historyLength[period]!))
              (s, e, spentIn(lines, t.categoryId, s, e)),
          ],
        );
      }(),
  ];
  views.sort((a, b) {
    final p = a.period.index.compareTo(b.period.index);
    return p != 0 ? p : (a.row.categoryId ?? '').compareTo(b.row.categoryId ?? '');
  });
  return views;
}

class StatsData {
  StatsData(this.scope, this.lines, this.from, this.to, this.statuses, this.previousComplete, {this.focus});

  final Scope scope;

  /// Already narrowed to [focus].
  final List<SpendLine> lines;

  /// Group or category the page is narrowed to, if any.
  final String? focus;

  /// [all] narrowed to [focus] (for tabs loading their own lines).
  List<SpendLine> narrow(List<SpendLine> all) => focus == null
      ? all
      : [
          for (final x in all)
            if (inFocus(x.categoryId, focus!)) x,
        ];

  /// Filter on [focus] for transaction lists.
  String? get focusCategory => focus == null || focus!.isEmpty ? null : focus;
  final DateTime from;
  final DateTime to;

  /// One per month of the range: which statements are missing.
  final List<MonthStatus> statuses;

  /// Every month of the previous period is fully covered by statements.
  final bool previousComplete;

  List<bool> get complete => [for (final s in statuses) s.complete];
  int get completeMonths => complete.where((c) => c).length;

  /// Monthly average over complete months only.
  int averageOf(List<int> monthly) => averageOverComplete(monthly, complete);

  /// Both periods are fully covered by statements: changes can be shown.
  bool get comparable => previousComplete && complete.every((c) => c);

  /// Change vs previous period, only when both periods are complete.
  double? changeOf(Breakdown b) => comparable ? b.change : null;

  String get currency => scopeCurrency(scope);
  List<DateTime> get months => monthsBetween(from, to);
  List<SpendLine> get inRange => [
    for (final l in lines)
      if (!l.date.isBefore(from) && l.date.isBefore(to)) l,
  ];
}
