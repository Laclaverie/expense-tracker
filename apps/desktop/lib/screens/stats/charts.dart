// Chart pieces shared by the Statistics tabs (colors, KPIs, cards, monthly bars).

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../style.dart';

const chartBlue = Color(0xFF2A78D6), chartAqua = Color(0xFF1BAF7A), chartRed = Color(0xFFE34948);

String percentChange(double v) => '${v >= 0 ? '+' : '−'}${(v.abs() * 100).round()} %';

/// A savings rate: `23 %`, `−12 %` when spending is above income.
String percentRate(double v) => '${v < 0 ? '−' : ''}${(v.abs() * 100).round()} %';

/// Income and spending per month of [months] from `(yyyy-mm, spending, income)` rows.
(List<int>, List<int>) incomeSpending(List<DateTime> months, List<(String, int, int)> totals) {
  final byMonth = {for (final t in totals) t.$1: t};
  String ym(DateTime m) => '${m.year}-${m.month.toString().padLeft(2, '0')}';
  return ([for (final m in months) byMonth[ym(m)]?.$3 ?? 0], [for (final m in months) byMonth[ym(m)]?.$2 ?? 0]);
}

/// Change vs the previous period: arrow + signed percentage (never color alone).
class ChangeBadge extends StatelessWidget {
  const ChangeBadge(this.change, {super.key});

  final double? change;

  @override
  Widget build(BuildContext context) {
    final c = change;
    if (c == null) return const SizedBox.shrink();
    final up = c > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: up ? chartRed : chartBlue),
        Text(percentChange(c), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class Kpi extends StatelessWidget {
  const Kpi(this.label, this.value, {super.key, this.sub});

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
              if (sub != null) Text(sub!, style: t.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.child, this.legend = const [], this.note});

  final String title;
  final Widget child;
  final List<(String, Color)> legend;

  /// A figure next to the title (e.g. the savings rate).
  final String? note;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              if (note != null) Text(note!, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              children: [
                for (final (name, color) in legend)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 14, height: 3, color: color),
                      const SizedBox(width: 6),
                      Text(name, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(height: 240, child: child),
        ],
      ),
    ),
  );
}

FlTitlesData monthTitles(BuildContext context, List<DateTime> months) {
  final small = Theme.of(context).textTheme.bodySmall;
  final compact = NumberFormat.compact(locale: lang(context));
  final step = max(1, (months.length / 12).ceil());
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 48,
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
          final m = months[i];
          final label = m.month == 1 || i == 0
              ? DateFormat.yMMM(lang(context)).format(m)
              : DateFormat.MMM(lang(context)).format(m);
          return SideTitleWidget(
            meta: meta,
            child: Text(label, style: small),
          );
        },
      ),
    ),
  );
}

/// Monthly spending, one series, with the average as a dashed reference line.
class MonthlyBars extends StatelessWidget {
  const MonthlyBars({
    super.key,
    required this.months,
    required this.values,
    required this.average,
    required this.currency,
    this.complete,
  });

  final List<DateTime> months;
  final List<int> values;
  final int average;
  final String currency;

  /// Per month; incomplete months are drawn lighter and flagged in the tooltip.
  final List<bool>? complete;

  bool _complete(int i) => complete == null || complete![i];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = values.isEmpty ? 1 : values.reduce(max) / 100;
    final width = months.length > 24 ? 6.0 : (months.length > 12 ? 10.0 : 18.0);
    return BarChart(
      BarChartData(
        maxY: top <= 0 ? 1 : top * 1.12,
        minY: min(0, values.isEmpty ? 0 : values.reduce(min) / 100),
        barGroups: [
          for (final (i, v) in values.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: v / 100,
                  width: width,
                  color: _complete(i) ? chartBlue : chartBlue.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: average / 100,
              color: scheme.onSurfaceVariant,
              strokeWidth: 1,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: Theme.of(context).textTheme.bodySmall,
                labelResolver: (_) =>
                    '${AppLocalizations.of(context).statAverage} ${money(context, average, currency)}',
              ),
            ),
          ],
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: monthTitles(context, months),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            fitInsideHorizontally: true,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${monthLabel(context, months[group.x])}\n${money(context, values[group.x], currency)}'
              '${_complete(group.x) ? '' : ' (${AppLocalizations.of(context).incomplete})'}',
              TextStyle(color: scheme.onInverseSurface),
            ),
          ),
        ),
      ),
    );
  }
}
