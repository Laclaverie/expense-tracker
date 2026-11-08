// Statistics → Trends tab: monthly totals, groups, income vs spending.

import 'dart:math';

import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../../l10n/app_localizations.dart';
import '../../style.dart';
import '../../widgets/keyed_stream.dart';
import '../../widgets/sparkline.dart';
import 'charts.dart';
import 'merchants.dart';

class TrendsTab extends StatelessWidget {
  const TrendsTab(this.d, {super.key, required this.onFocus});

  final StatsData d;

  /// Narrows the page to a group or category.
  final ValueChanged<String> onFocus;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final monthly = monthlyTotals(d.lines, d.from, d.to);
    final total = monthly.fold(0, (s, v) => s + v);
    final (pf, pt) = previousPeriod(d.from, d.to);
    final previous = monthlyTotals(d.lines, pf, pt).fold(0, (s, v) => s + v);
    final average = d.averageOf(monthly);
    final comparable = d.previousComplete && d.complete.every((c) => c);
    // Most / least expensive among complete months (a month missing a statement looks cheap).
    final withData = [
      for (final (i, v) in monthly.indexed)
        if (v != 0 && (d.complete[i] || d.completeMonths == 0)) (d.months[i], v),
    ];
    final maxMonth = withData.isEmpty ? null : withData.reduce((a, b) => a.$2 >= b.$2 ? a : b);
    final minMonth = withData.isEmpty ? null : withData.reduce((a, b) => a.$2 <= b.$2 ? a : b);
    final groups = breakdown(d.lines, d.from, d.to, keyOf: (x) => groupKey(x.categoryId), labelOf: (k) => k);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Kpi(l.statTotal, money(context, total, d.currency)),
            Kpi(
              l.statAverage,
              money(context, average, d.currency),
              sub: d.completeMonths < d.months.length && d.completeMonths > 0
                  ? l.overCompleteMonths(d.completeMonths)
                  : null,
            ),
            Kpi(
              l.statVsPrevious,
              previous <= 0 || !comparable ? '—' : percentChange((total - previous) / previous),
              sub: !comparable ? l.previousIncomplete : (previous <= 0 ? null : money(context, previous, d.currency)),
            ),
            if (maxMonth != null)
              Kpi(l.statMostExpensive, money(context, maxMonth.$2, d.currency), sub: monthLabel(context, maxMonth.$1)),
            if (minMonth != null)
              Kpi(l.statLeastExpensive, money(context, minMonth.$2, d.currency), sub: monthLabel(context, minMonth.$1)),
          ],
        ),
        const SizedBox(height: 16),
        if (d.focus != null)
          ..._focused(context, monthly, average)
        else ...[
          ChartCard(
            title: l.chartMonthlySpending,
            child: MonthlyBars(
              months: d.months,
              values: monthly,
              average: average,
              currency: d.currency,
              complete: d.complete,
            ),
          ),
          const SizedBox(height: 16),
          KeyedStreamBuilder<List<(String, int, int)>>(
            streamKey: (d.scope, d.from, d.to),
            stream: () => context.read<ExpenseRepository>().watchMonthlyTotals(d.scope, d.from, d.to),
            builder: (context, totals) {
              final (income, spending) = incomeSpending(d.months, totals ?? const []);
              final rate = savingsRate(income, spending, d.complete);
              return ChartCard(
                title: l.chartIncomeSpending,
                note: rate == null
                    ? null
                    : l.savingsRateOver(percentRate(rate), d.completeMonths > 0 ? d.completeMonths : d.months.length),
                legend: [(l.legendSpending, chartBlue), (l.legendIncome, chartAqua)],
                child: _IncomeSpending(
                  months: d.months,
                  complete: d.complete,
                  totals: totals ?? const [],
                  currency: d.currency,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(l.byGroupTrend, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final g in groups.where((g) => g.total > 0))
                _TrendCard(
                  d,
                  g,
                  title: index.name(context, g.key.isEmpty ? null : g.key),
                  color: groupColor(context, g.key),
                  onTap: () => onFocus(g.key),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// Narrowed to a group or category: where the money goes store by store,
  /// then one card per category (for a group) and per store.
  List<Widget> _focused(BuildContext context, List<int> monthly, int average) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final names = <String, String>{};
    final stores = breakdown(
      d.lines,
      d.from,
      d.to,
      keyOf: (x) {
        if (x.isPerson || x.merchantId == null) return null;
        names['${x.merchantId}'] = x.merchant;
        return '${x.merchantId}';
      },
      labelOf: (k) => names[k] ?? k,
    ).where((r) => r.total > 0).toList();
    const shown = 5;
    final top = stores.take(shown).toList();
    final others = [for (final (i, v) in monthly.indexed) v - top.fold<int>(0, (s, r) => s + r.monthly[i])];
    final series = [
      for (final (i, r) in top.indexed) (r.label, seriesColor(context, i), r.monthly),
      if (others.any((v) => v > 0)) (l.other, groupColor(context, otherSeries), others),
    ];
    final focus = d.focus!;
    final categories = focus.isEmpty || focus.contains('.')
        ? const <Breakdown>[]
        : breakdown(
            d.lines,
            d.from,
            d.to,
            keyOf: (x) => x.categoryId ?? '',
            labelOf: (k) => k,
          ).where((c) => c.total > 0).toList();
    final t = Theme.of(context).textTheme;
    return [
      ChartCard(
        title: l.chartSpendingByStore,
        legend: [for (final (name, color, _) in series) (name, color)],
        child: _StackedBars(
          months: d.months,
          series: series,
          average: average,
          currency: d.currency,
          complete: d.complete,
        ),
      ),
      if (categories.length > 1) ...[
        const SizedBox(height: 16),
        Text(l.byCategoryTrend, style: t.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in categories)
              _TrendCard(
                d,
                c,
                title: index.name(context, c.key.isEmpty ? null : c.key),
                color: groupColor(context, c.key),
                onTap: () => onFocus(c.key),
              ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      Text(l.byStore, style: t.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final (i, s) in stores.indexed)
            _TrendCard(
              d,
              s,
              title: s.label,
              color: i < shown ? seriesColor(context, i) : groupColor(context, otherSeries),
              onTap: () => showMerchant(context, d, s),
              details: _storeDetails(context, s),
            ),
        ],
      ),
    ];
  }

  /// Purchases per month, average basket and its change vs the previous period.
  String _storeDetails(BuildContext context, Breakdown s) {
    final l = AppLocalizations.of(context);
    final perMonth = NumberFormat.decimalPatternDigits(
      locale: lang(context),
      decimalDigits: 1,
    ).format(s.count / d.months.length);
    final ticketChange = d.previousComplete && d.complete.every((c) => c) ? s.ticketChange : null;
    return '${l.purchasesPerMonth(perMonth)} · ${l.averageTicket} ${money(context, s.averageTicket, d.currency)}'
        '${ticketChange == null ? '' : ' (${percentChange(ticketChange)})'}';
  }
}

/// Small multiple: total, change, monthly average and a sparkline.
class _TrendCard extends StatelessWidget {
  const _TrendCard(this.d, this.b, {required this.title, required this.color, required this.onTap, this.details});

  final StatsData d;
  final Breakdown b;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 250,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 5, backgroundColor: color),
                    const SizedBox(width: 6),
                    Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
                    ChangeBadge(d.changeOf(b)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(money(context, b.total, d.currency), style: t.titleLarge),
                Text(
                  '${money(context, d.averageOf(b.monthly), d.currency)} ${l.perMonth}'
                  // Store cards are many: the note is in the KPI above, not repeated.
                  '${details == null && d.completeMonths < d.months.length && d.completeMonths > 0 ? ' · ${l.overCompleteMonths(d.completeMonths)}' : ''}',
                  style: t.bodySmall,
                ),
                if (details != null) Text(details!, style: t.bodySmall),
                const SizedBox(height: 6),
                Sparkline(b.monthly, color: color, width: 220, height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Monthly spending stacked by series (stores), with the average as a dashed
/// line. Incomplete months are lighter.
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
  final int average;
  final String currency;
  final List<bool> complete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = Theme.of(context).cardTheme.color ?? scheme.surfaceContainerLow;
    final width = months.length > 24 ? 6.0 : (months.length > 12 ? 10.0 : 18.0);
    final totals = [for (final (i, _) in months.indexed) series.fold(0, (s, x) => s + max(0, x.$3[i]))];
    final top = totals.isEmpty ? 0 : totals.reduce(max) / 100;
    return BarChart(
      BarChartData(
        maxY: max(top, average / 100) * 1.12 + 1,
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }(),
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
            fitInsideVertically: true,
            getTooltipItem: (group, _, _, _) {
              final i = group.x;
              final parts = [
                for (final (name, _, values) in series.reversed)
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

/// Income and spending per month: two lines on the same money axis. The
/// income line skips incomplete months: a missing account statement is not
/// a month without pay.
class _IncomeSpending extends StatelessWidget {
  const _IncomeSpending({required this.months, required this.complete, required this.totals, required this.currency});

  final List<DateTime> months;
  final List<bool> complete;
  final List<(String, int, int)> totals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final byMonth = {for (final t in totals) t.$1: t};
    String ym(DateTime m) => '${m.year}-${m.month.toString().padLeft(2, '0')}';
    List<FlSpot> spots(int Function((String, int, int)) pick, {bool skipIncomplete = false}) => [
      for (final (i, m) in months.indexed)
        if (skipIncomplete && !complete[i])
          FlSpot.nullSpot
        else
          FlSpot(i.toDouble(), (byMonth[ym(m)] == null ? 0 : pick(byMonth[ym(m)]!)) / 100),
    ];
    LineChartBarData series(List<FlSpot> s, Color c) => LineChartBarData(
      spots: s,
      color: c,
      barWidth: 2,
      isCurved: false,
      dotData: FlDotData(
        show: months.length <= 24,
        getDotPainter: (_, _, _, _) =>
            FlDotCirclePainter(radius: 4, color: c, strokeWidth: 2, strokeColor: scheme.surfaceContainerLow),
      ),
    );
    return LineChart(
      LineChartData(
        minY: 0,
        lineBarsData: [
          series(spots((t) => t.$2), chartBlue),
          series(spots((t) => t.$3, skipIncomplete: true), chartAqua),
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: monthTitles(context, months),
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (_, idx) => [
            for (final _ in idx)
              TouchedSpotIndicatorData(FlLine(color: scheme.onSurfaceVariant, strokeWidth: 1), const FlDotData()),
          ],
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            fitInsideHorizontally: true,
            getTooltipItems: (spots) {
              final (income, spending) = incomeSpending(months, totals);
              String rate(int i) {
                final r = savingsRate([income[i]], [spending[i]], const [true]);
                return r == null ? '' : '\n${l.savingsRate}  ${percentRate(r)}';
              }

              return [
                for (final s in spots)
                  LineTooltipItem(
                    '${s.barIndex == 0 ? '${monthLabel(context, months[s.x.toInt()])}'
                              '${complete[s.x.toInt()] ? '' : ' (${l.incomplete})'}\n' : ''}'
                    '${s.barIndex == 0 ? l.legendSpending : l.legendIncome}  ${money(context, (s.y * 100).round(), currency)}'
                    '${s.barIndex == 1 ? rate(s.x.toInt()) : ''}',
                    TextStyle(color: scheme.onInverseSurface),
                  ),
              ];
            },
          ),
        ),
      ),
    );
  }
}
