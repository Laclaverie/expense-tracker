// Statistics → Balances tab: month-end balances and money in / out per year.

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
import 'charts.dart';

/// Month-end balance of each account holding money (checking, savings,
/// registered) and money in / out per year. Not limited by the spending
/// coverage rules: balances come from statements, one account at a time.
class BalancesTab extends StatelessWidget {
  const BalancesTab(this.scope, this.period, {super.key});

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
        if (series.isEmpty) return Center(child: Text(l.balancesNone));
        final first = series.map((s) => s.$2.first.month).reduce((a, b) => a.isBefore(b) ? a : b);
        final last = series.map((s) => s.$2.last.month).reduce((a, b) => a.isAfter(b) ? a : b);
        final months = monthsBetween(first, DateTime.utc(last.year, last.month + 1));
        final t = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (i, (a, ms)) in series.indexed)
                  SizedBox(
                    width: 280,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 5, backgroundColor: seriesColor(context, i)),
                                const SizedBox(width: 6),
                                Icon(accountIcon(a.type), size: 16),
                                const SizedBox(width: 6),
                                Expanded(child: Text(accountName(a), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              money(context, ms.last.closing, currency),
                              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${l.balanceChange} : ${_signed(context, ms.last.closing - (ms.first.closing - ms.first.net), currency)}',
                              style: t.bodySmall,
                            ),
                            if (ms.any((m) => m.interest != 0))
                              Text(
                                l.interestOf(money(context, ms.fold(0, (s, m) => s + m.interest), currency)),
                                style: t.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ChartCard(
              title: l.chartBalances,
              legend: [for (final (i, (a, _)) in series.indexed) (accountName(a), seriesColor(context, i))],
              child: _BalanceLines(months: months, series: series, currency: currency),
            ),
            const SizedBox(height: 8),
            // The period asks for more than is known (walking back stops at a missing statement).
            if (first.isAfter(from)) Text(l.balancesFrom(monthLabel(context, first)), style: t.bodySmall),
            Text(l.balancesHint, style: t.bodySmall),
            for (final (a, ms) in series) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(accountIcon(a.type), size: 18),
                  const SizedBox(width: 8),
                  Text(accountName(a), style: t.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              _YearTable(ms, currency),
            ],
          ],
        );
      },
    );
  }
}

String _signed(BuildContext context, int cents, String currency) =>
    '${cents > 0 ? '+' : ''}${money(context, cents, currency)}';

/// Money in / out per calendar year, with the balance at the end of each year.
class _YearTable extends StatelessWidget {
  const _YearTable(this.months, this.currency);

  final List<MonthBalance> months;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final byYear = <int, List<MonthBalance>>{};
    for (final m in months) {
      byYear.putIfAbsent(m.month.year, () => []).add(m);
    }
    final small = Theme.of(context).textTheme.labelMedium;
    Widget cell(String text, {TextStyle? style, double width = 130}) => SizedBox(
      width: width,
      child: Text(text, textAlign: TextAlign.right, style: style),
    );
    return Card(
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(l.colYear, style: small)),
                cell(l.colDeposits, style: small),
                cell(l.colWithdrawals, style: small),
                cell(l.colInterest, style: small, width: 100),
                cell(l.colChange, style: small, width: 170),
                cell(l.colYearEnd, style: small),
              ],
            ),
          ),
          for (final MapEntry(key: year, value: ms) in byYear.entries.toList().reversed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ms.length == 12
                          ? '$year'
                          : '$year (${DateFormat.MMM(lang(context)).format(ms.first.month)} – '
                                '${DateFormat.MMM(lang(context)).format(ms.last.month)})',
                    ),
                  ),
                  cell(money(context, ms.fold(0, (s, m) => s + m.deposits), currency)),
                  cell(money(context, -ms.fold(0, (s, m) => s + m.withdrawals), currency)),
                  cell(money(context, ms.fold(0, (s, m) => s + m.interest), currency), width: 100),
                  cell(
                    _signed(context, ms.fold(0, (s, m) => s + m.net), currency),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    width: 170,
                  ),
                  cell(money(context, ms.last.closing, currency)),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

/// One line per account; months without a known balance are left out.
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
              dotData: FlDotData(
                show: months.length <= 24,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 3,
                  color: seriesColor(context, i),
                  strokeWidth: 1.5,
                  strokeColor: scheme.surfaceContainerLow,
                ),
              ),
            ),
        ],
        minY: 0,
        // Headroom so a flat line (an account without movements) stays inside the axis.
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
