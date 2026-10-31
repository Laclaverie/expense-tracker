import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:storage/storage.dart';

import 'l10n/app_localizations.dart';
import 'style.dart';

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

/// Reserved status colors (never reused for categories), always shown with an
/// icon and a label.
const _good = Color(0xFF0CA30C), _warning = Color(0xFFFAB219), _critical = Color(0xFFD03B3B);

Color statusColor(TargetStatus s) => switch (s) {
  TargetStatus.onTrack => _good,
  TargetStatus.atRisk => _warning,
  TargetStatus.over => _critical,
};

IconData statusIcon(TargetStatus s) => switch (s) {
  TargetStatus.onTrack => Icons.check_circle,
  TargetStatus.atRisk => Icons.warning_amber_rounded,
  TargetStatus.over => Icons.error,
};

String statusLabel(AppLocalizations l, TargetStatus s) => switch (s) {
  TargetStatus.onTrack => l.status_onTrack,
  TargetStatus.atRisk => l.status_atRisk,
  TargetStatus.over => l.status_over,
};

String periodLabel(AppLocalizations l, TargetPeriod p) => switch (p) {
  TargetPeriod.week => l.period_week,
  TargetPeriod.month => l.period_month,
  TargetPeriod.year => l.period_year,
};

/// `Octobre 2026`, `12 – 18 oct.`, `2026`.
String periodName(BuildContext context, TargetPeriod p, DateTime start, DateTime end) => switch (p) {
  TargetPeriod.month => monthLabel(context, start),
  TargetPeriod.year => '${start.year}',
  TargetPeriod.week =>
    '${DateFormat.d(lang(context)).format(start)} – ${shortDate(context, end.subtract(const Duration(days: 1)))}',
};

String targetName(BuildContext context, CategoryIndex index, String? categoryId) =>
    categoryId == null ? AppLocalizations.of(context).allSpending : index.name(context, categoryId);

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final TargetStatus status;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(statusIcon(status), color: statusColor(status), size: 18),
      const SizedBox(width: 4),
      Text(statusLabel(AppLocalizations.of(context), status)),
    ],
  );
}

class TargetBar extends StatelessWidget {
  const TargetBar(this.progress, {super.key});

  final TargetProgress progress;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: LinearProgressIndicator(
      value: progress.ratio.clamp(0, 1).toDouble(),
      minHeight: 8,
      color: statusColor(progress.status),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
  );
}
