import 'dart:math';

import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../../keyed_stream.dart';
import '../../l10n/app_localizations.dart';
import '../../style.dart';
import 'widgets.dart';

/// Month-end balance per account over the period (balances come from statements, one account at a time).
class BalancesView extends StatelessWidget {
  const BalancesView(this.scope, this.period, {super.key});

  final Scope scope;
  final (DateTime, DateTime) period;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = scopeCurrency(scope);
    return KeyedStreamBuilder<List<(Account, List<MonthBalance>)>>(
      streamKey: scope,
      stream: () => context.read<ExpenseRepository>().watchBalanceHistory(scope),
      builder: (context, history) {
        if (history == null) return const Center(child: CircularProgressIndicator());
        final (from, to) = period;
        final series = [
          for (final (a, months) in history)
            (
              a,
              [
                for (final m in months)
                  if (!m.month.isBefore(from) && m.month.isBefore(to)) m,
              ],
            ),
        ].where((s) => s.$2.isNotEmpty).toList();
        if (series.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.balancesNone, textAlign: TextAlign.center),
            ),
          );
        }
        final first = series.map((s) => s.$2.first.month).reduce((a, b) => a.isBefore(b) ? a : b);
        final last = series.map((s) => s.$2.last.month).reduce((a, b) => a.isAfter(b) ? a : b);
        final months = monthsBetween(first, DateTime.utc(last.year, last.month + 1));
        final t = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: [
            for (final (i, (a, ms)) in series.indexed)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(accountIcon(a.type), color: seriesColor(context, i)),
                  title: Text(accountName(a), overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    l.balanceChange(_signed(context, ms.last.closing - (ms.first.closing - ms.first.net), currency)),
                  ),
                  trailing: Text(
                    money(context, ms.last.closing, currency),
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            ChartCard(
              title: l.chartBalances,
              child: _BalanceLines(months: months, series: series, currency: currency),
            ),
            const SizedBox(height: 8),
            if (first.isAfter(from)) Text(l.balancesFrom(monthLabel(context, first)), style: t.bodySmall),
          ],
        );
      },
    );
  }
}

String _signed(BuildContext context, int cents, String currency) =>
    '${cents > 0 ? '+' : ''}${money(context, cents, currency)}';

class _BalanceLines extends StatelessWidget {
  const _BalanceLines({required this.months, required this.series, required this.currency});

  final List<DateTime> months;
  final List<(Account, List<MonthBalance>)> series;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = {for (final (i, m) in months.indexed) m: i};
    return LineChart(
      LineChartData(
        lineBarsData: [
          for (final (i, (_, ms)) in series.indexed)
            LineChartBarData(
              spots: [for (final m in ms) FlSpot(index[m.month]!.toDouble(), m.closing / 100)],
              color: seriesColor(context, i),
              barWidth: 2,
              dotData: FlDotData(show: months.length <= 12),
            ),
        ],
        minY: min(0, series.expand((s) => s.$2).map((m) => m.closing / 100).fold<double>(0, min)),
        maxY: series.expand((s) => s.$2).map((m) => m.closing / 100).fold<double>(1, max) * 1.15,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: monthTitles(context, months),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            fitInsideHorizontally: true,
            getTooltipItems: (spots) => [
              for (final (k, s) in spots.indexed)
                LineTooltipItem(
                  '${k == 0 ? '${monthLabel(context, months[s.x.toInt()])}\n' : ''}'
                  '${accountName(series[s.barIndex].$1)}  ${money(context, (s.y * 100).round(), currency)}',
                  TextStyle(color: scheme.onInverseSurface),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
