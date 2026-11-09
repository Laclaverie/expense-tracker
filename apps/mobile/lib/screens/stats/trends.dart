import 'dart:math';

import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../../l10n/app_localizations.dart';
import '../../style.dart';
import 'widgets.dart';

/// Spending per month, stacked by group, as the desktop's Trends tab. Months missing a statement are faded and
/// left out of the average.
class TrendsView extends StatelessWidget {
  const TrendsView(this.d, {super.key, this.notices = const []});

  final StatsData d;
  final List<Widget> notices;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final monthly = monthlyTotals(d.lines, d.from, d.to);
    final total = monthly.fold(0, (s, v) => s + v);
    // No complete month: no average (core's would fall back to incomplete months, which look cheap).
    final int? average = d.completeMonths == 0 ? null : d.averageOf(monthly);
    // One series per chart group (others merged), largest first.
    final bySeries = <String, List<int>>{};
    for (final g in breakdown(d.lines, d.from, d.to, keyOf: (x) => groupKey(x.categoryId), labelOf: (k) => k)) {
      final s = bySeries.putIfAbsent(seriesOf(g.key), () => List.filled(d.months.length, 0));
      for (final (i, v) in g.monthly.indexed) {
        s[i] += v;
      }
    }
    final series = [
      for (final MapEntry(:key, :value) in bySeries.entries)
        (
          key == otherSeries ? l.other : index.name(context, key == uncategorizedSeries ? null : key),
          key == otherSeries ? otherColor(context) : groupColor(context, key == uncategorizedSeries ? null : key),
          value,
        ),
    ]..sort((a, b) => b.$3.fold(0, (s, v) => s + v).compareTo(a.$3.fold(0, (s, v) => s + v)));
    final partial = d.completeMonths < d.months.length && d.completeMonths > 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        ...notices,
        kpiRow(
          Kpi(l.statTotal, money(context, total, d.currency)),
          Kpi(
            l.statAverage,
            average == null ? '—' : money(context, average, d.currency),
            sub: partial ? l.overCompleteMonths(d.completeMonths) : null,
          ),
        ),
        const SizedBox(height: 12),
        ChartCard(
          title: l.chartMonthlySpending,
          child: _StackedBars(
            months: d.months,
            series: series,
            average: average,
            currency: d.currency,
            complete: d.complete,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final (name, color, _) in series)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 5, backgroundColor: color),
                  const SizedBox(width: 4),
                  Text(name, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
          ],
        ),
        if (d.complete.any((c) => !c)) ...[
          const SizedBox(height: 8),
          Text(l.fadedIncomplete, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _StackedBars extends StatelessWidget {
  const _StackedBars({
    required this.months,
    required this.series,
    required this.average,
    required this.currency,
    required this.complete,
  });

  final List<DateTime> months;
  final List<(String, Color, List<int>)> series;

  /// Null: no complete month, no line.
  final int? average;
  final String currency;
  final List<bool> complete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = Theme.of(context).cardTheme.color ?? scheme.surfaceContainerLow;
    final width = months.length > 12 ? 6.0 : 12.0;
    final totals = [for (final (i, _) in months.indexed) series.fold(0, (s, x) => s + max(0, x.$3[i]))];
    final top = totals.isEmpty ? 0 : totals.reduce(max) / 100;
    return BarChart(
      BarChartData(
        maxY: max(top, (average ?? 0) / 100) * 1.12 + 1,
        barGroups: [
          for (final (i, _) in months.indexed)
            () {
              var y = 0.0;
              final stack = <BarChartRodStackItem>[];
              for (final (_, color, values) in series) {
                final v = max(0, values[i]) / 100;
                if (v <= 0) continue;
                stack.add(
                  BarChartRodStackItem(
                    y,
                    y + v,
                    complete[i] ? color : color.withValues(alpha: 0.35),
                    borderSide: BorderSide(color: surface, width: 1),
                  ),
                );
                y += v;
              }
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: y,
                    width: width,
                    rodStackItems: stack,
                    color: Colors.transparent,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ],
              );
            }(),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (average != null)
              HorizontalLine(
                y: average! / 100,
                color: scheme.onSurfaceVariant,
                strokeWidth: 1.5,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 4, bottom: 2),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurface, backgroundColor: scheme.surface.withValues(alpha: 0.8)),
                  labelResolver: (_) => AppLocalizations.of(context).averageShort(money(context, average!, currency)),
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
            fitInsideVertically: true,
            getTooltipItem: (group, _, _, _) {
              final i = group.x;
              final parts = [
                for (final (name, _, values) in series)
                  if (values[i] > 0) '$name  ${money(context, values[i], currency)}',
              ];
              return BarTooltipItem(
                '${monthLabel(context, months[i])}  ${money(context, totals[i], currency)}'
                '${complete[i] ? '' : ' (${AppLocalizations.of(context).incomplete})'}\n${parts.join('\n')}',
                TextStyle(color: scheme.onInverseSurface),
              );
            },
          ),
        ),
      ),
    );
  }
}
