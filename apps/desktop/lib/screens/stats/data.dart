// What every Statistics tab reads: the scope, its lines and the range.

import 'package:core/core.dart';
import 'package:storage/storage.dart';

import '../../coverage_view.dart';
import '../../style.dart';

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
