import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'style.dart';

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
