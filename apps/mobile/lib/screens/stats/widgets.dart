import 'dart:math';

import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../style.dart';

/// A short notice above a view (coverage, start of the data).
class StatsNotice extends StatelessWidget {
  const StatsNotice(this.icon, this.text, {super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    ),
  );
}

/// A figure with its label (and an optional line under it).
class Kpi extends StatelessWidget {
  const Kpi(this.label, this.value, {super.key, this.sub});

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (sub != null) Text(sub!, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// A titled card holding a chart of fixed height.
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.child, this.height = 220});

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          SizedBox(height: height, child: child),
        ],
      ),
    ),
  );
}

/// Axis titles for a chart with one x per month: compact amounts on the left, a few month names below (phone
/// width fits about six).
FlTitlesData monthTitles(BuildContext context, List<DateTime> months) {
  final small = Theme.of(context).textTheme.bodySmall;
  final compact = NumberFormat.compact(locale: lang(context));
  final step = max(1, (months.length / 6).ceil());
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        getTitlesWidget: (v, meta) => v == meta.max
            ? const SizedBox.shrink()
            : SideTitleWidget(
                meta: meta,
                child: Text(compact.format(v), style: small),
              ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1,
        getTitlesWidget: (v, meta) {
          final i = v.toInt();
          if (i < 0 || i >= months.length || i % step != 0 || v != i.toDouble()) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            child: Text(DateFormat.MMM(lang(context)).format(months[i]), style: small),
          );
        },
      ),
    ),
  );
}

String cadenceLabel(AppLocalizations l, Cadence c) => switch (c) {
  Cadence.weekly => l.cadenceWeekly,
  Cadence.biweekly => l.cadenceBiweekly,
  Cadence.monthly => l.cadenceMonthly,
  Cadence.bimonthly => l.cadenceBimonthly,
  Cadence.quarterly => l.cadenceQuarterly,
  Cadence.semiannual => l.cadenceSemiannual,
  Cadence.yearly => l.cadenceYearly,
};

/// Two KPIs side by side.
Widget kpiRow(Kpi a, Kpi b) => IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: a),
      const SizedBox(width: 8),
      Expanded(child: b),
    ],
  ),
);
