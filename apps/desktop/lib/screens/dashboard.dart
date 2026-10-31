import 'dart:math';

import 'package:core/core.dart' show DayRange, MonthBalance, savingsRate;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../app_state.dart';
import '../coverage_view.dart';
import '../l10n/app_localizations.dart';
import '../style.dart';
import '../targets_view.dart';
import '../widgets/keyed_stream.dart';
import '../widgets/transactions_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scope = state.scope;
    final l = AppLocalizations.of(context);
    if (scope == null) return Center(child: Text(l.noData));
    final repo = context.read<ExpenseRepository>();
    final month = state.month, next = state.nextMonth;
    final key = (scope, month, lang(context));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        KeyedStreamBuilder<List<(String, int, int)>>(
          streamKey: key,
          stream: () => repo.watchMonthlyTotals(scope, DateTime.utc(month.year, month.month - 6), next),
          builder: (context, totals) => KeyedStreamBuilder<Map<String, List<DayRange>>>(
            streamKey: scope,
            stream: () => repo.watchCoverage(scope),
            builder: (context, coverage) {
              final statuses = monthStatuses(coverage ?? const {}, [
                for (var i = 6; i >= 0; i--) DateTime.utc(month.year, month.month - i),
              ]);
              // A month its statements cover but without lines is just a quiet account.
              final waiting = coverage != null && (coverage.isEmpty || !statuses.last.complete);
              return Column(
                children: [
                  if (totals != null && waiting && !totals.any((t) => t.$1 == _ym(month))) _EmptyMonth(month),
                  _Kpis(totals ?? const [], month, _currency(scope), statuses, balance: _BalanceTile(scope, month)),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _TargetsCard(scope.whole, state.referenceDay, _currency(scope)),
        const SizedBox(height: 16),
        // The 12-month chart is context: it stays on the latest months with data and
        // highlights the selected month instead of sliding with it.
        KeyedStreamBuilder<DateTime?>(
          streamKey: scope,
          stream: () => repo.watchLatestDate(scope),
          builder: (context, latest) {
            final end = chartEnd(month, latest);
            return KeyedStreamBuilder<List<Amount>>(
              streamKey: (scope, end, lang(context)),
              stream: () => repo.watchMonthlyByGroup(
                scope,
                DateTime.utc(end.year, end.month - 11),
                DateTime.utc(end.year, end.month + 1),
                lang: lang(context),
              ),
              builder: (context, rows) => _MonthlyChart(
                rows ?? const [],
                end,
                _currency(scope),
                selected: month,
                onSelect: (m) => state.month = m,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: KeyedStreamBuilder<List<Amount>>(
                streamKey: key,
                stream: () => repo.watchSpendingByCategory(scope, month, next, lang: lang(context)),
                builder: (context, rows) => _RankedList(
                  title: l.byCategory,
                  rows: rows ?? const [],
                  currency: _currency(scope),
                  colored: true,
                  onTap: (r) => showSpendingDialog(
                    context,
                    title:
                        '${context.read<CategoryIndex>().name(context, r.key.isEmpty ? null : r.key)} — '
                        '${monthLabel(context, month)}',
                    filter: TxnFilter(scope: scope, from: month, to: next, categoryId: r.key.isEmpty ? null : r.key),
                    uncategorizedOnly: r.key.isEmpty,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: KeyedStreamBuilder<List<Amount>>(
                streamKey: key,
                stream: () => repo.watchTopMerchants(scope, month, next),
                builder: (context, rows) => _RankedList(
                  title: l.topMerchants,
                  rows: rows ?? const [],
                  currency: _currency(scope),
                  onTap: (r) => int.tryParse(r.key) == null
                      ? null
                      : showSpendingDialog(
                          context,
                          title: '${r.label} — ${monthLabel(context, month)}',
                          filter: TxnFilter(scope: scope, from: month, to: next, merchantId: int.parse(r.key)),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l.transfersExcluded, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _currency(Scope scope) => scopeCurrency(scope);
}

String _ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// Last month of the 12-month chart: the month of the latest data, moved back
/// by whole years only when [selected] is older than the window (and forward
/// to [selected] when it is after the data).
DateTime chartEnd(DateTime selected, DateTime? latest) {
  if (latest == null) return selected;
  final end = DateTime.utc(latest.year, latest.month);
  if (!selected.isBefore(end)) return selected;
  final diff = (end.year * 12 + end.month) - (selected.year * 12 + selected.month);
  final pages = diff <= 11 ? 0 : ((diff - 11) / 12).ceil();
  return DateTime.utc(end.year, end.month - 12 * pages);
}

/// Balance of the selected account at the end of [month] (one account
/// selected, checking / savings / registered only).
class _BalanceTile extends StatelessWidget {
  const _BalanceTile(this.scope, this.month);

  final Scope scope;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    if (scope.accountId == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return KeyedStreamBuilder<List<(Account, List<MonthBalance>)>>(
      streamKey: scope,
      stream: () => context.read<ExpenseRepository>().watchBalanceHistory(scope),
      builder: (context, history) {
        if (history == null || history.isEmpty) return const SizedBox.shrink();
        final (account, months) = history.single;
        final at = months.where((m) => m.month == month).firstOrNull;
        final String value, label;
        String? sub;
        if (at != null) {
          (label, value) = (l.balanceEndOf(monthLabel(context, month)), money(context, at.closing, account.currency));
        } else if (month.isAfter(months.last.month)) {
          (label, value) = (l.balance, money(context, months.last.closing, account.currency));
          sub = l.balanceAsOf(DateFormat.yMMMd(lang(context)).format(account.balanceDate!));
        } else {
          (label, value) = (l.balanceEndOf(monthLabel(context, month)), '—');
        }
        return _Tile(label: label, value: value, sub: sub, gap: 16);
      },
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis(this.totals, this.month, this.currency, this.statuses, {required this.balance});

  final List<(String, int, int)> totals;
  final DateTime month;
  final String currency;

  /// The 6 previous months then the selected one.
  final List<MonthStatus> statuses;

  /// Shown last; empty unless one account is selected.
  final Widget balance;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = totals.where((t) => t.$1 == _ym(month)).firstOrNull;
    // Average over complete previous months only: a month missing a statement looks cheap.
    final complete = {
      for (final s in statuses)
        if (s.complete) _ym(s.month),
    };
    final previous = totals.where((t) => t.$1 != _ym(month) && complete.contains(t.$1)).toList();
    final average = previous.isEmpty ? null : previous.fold(0, (s, t) => s + t.$2) ~/ previous.length;
    final spent = current?.$2 ?? 0;
    final status = statuses.last;
    String? delta;
    if (!status.complete) {
      delta = '${l.incomplete} : ${status.gaps.map((g) => gapText(context, g)).join(', ')}';
    } else if (current != null && average != null && average > 0) {
      final pct = (spent - average) / average * 100;
      delta = l.vsAverage('${pct >= 0 ? '+' : ''}${pct.round()} %');
    }
    final m = monthLabel(context, month);
    // A month missing a statement would look thrifty: no rate then.
    final rate = status.complete ? savingsRate([current?.$3 ?? 0], [spent], const [true]) : null;
    return Row(
      children: [
        _Tile(label: l.spentIn(m), value: money(context, spent, currency), sub: delta),
        const SizedBox(width: 16),
        _Tile(label: l.average6, value: average == null ? '—' : money(context, average, currency)),
        const SizedBox(width: 16),
        _Tile(
          label: l.incomeIn(m),
          value: money(context, current?.$3 ?? 0, currency),
          sub: rate == null ? null : l.savingsRateIs('${rate < 0 ? '−' : ''}${(rate.abs() * 100).round()} %'),
        ),
        balance,
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.sub, this.gap = 0});

  final String label;
  final String value;
  final String? sub;

  /// Space on the left, for a tile that may be absent (no separator outside).
  final double gap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: gap),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(value, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (sub != null) ...[const SizedBox(height: 4), Text(sub!, style: t.bodySmall)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stacked bars: one per month, segments = category groups in fixed order
/// (fixed colors), the rest folded into "Other".
class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart(this.rows, this.month, this.currency, {required this.selected, required this.onSelect});

  final List<Amount> rows;

  /// Last month shown.
  final DateTime month;
  final String currency;

  /// Highlighted month; a click on a bar selects its month.
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final scheme = Theme.of(context).colorScheme;
    final months = [for (var i = 11; i >= 0; i--) DateTime.utc(month.year, month.month - i)];
    final series = [...chartGroups, otherSeries, uncategorizedSeries];
    String seriesName(String s) => switch (s) {
      otherSeries => l.other,
      uncategorizedSeries => l.uncategorized,
      _ => index.name(context, s),
    };
    final values = <String, Map<String, int>>{};
    for (final r in rows) {
      final byGroup = values.putIfAbsent(r.month!, () => {});
      byGroup.update(seriesOf(r.key), (v) => v + r.cents, ifAbsent: () => r.cents);
    }
    final maxTotal = values.values.map((g) => g.values.where((v) => v > 0).fold(0, (s, v) => s + v)).fold(0, max);
    final maxY = maxTotal == 0 ? 1.0 : maxTotal / 100 * 1.1;
    final surface = Theme.of(context).cardTheme.color ?? scheme.surfaceContainerLow;

    final groups = [
      for (final (i, m) in months.indexed)
        () {
          var y = 0.0;
          final stack = <BarChartRodStackItem>[];
          for (final s in series) {
            final v = (values[_ym(m)]?[s] ?? 0).clamp(0, 1 << 40) / 100;
            if (v <= 0) continue;
            stack.add(
              BarChartRodStackItem(
                y,
                y + v,
                groupColor(context, s),
                borderSide: BorderSide(color: surface, width: 1), // 2px gap between segments
              ),
            );
            y += v;
          }
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: y,
                width: 22,
                rodStackItems: stack,
                color: Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: m == selected,
                  toY: maxY,
                  color: scheme.primary.withValues(alpha: 0.14),
                ),
              ),
            ],
          );
        }(),
    ];

    final compact = NumberFormat.compact(locale: lang(context));
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.monthlyByGroup, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                for (final s in series)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: groupColor(context, s),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(seriesName(s), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barGroups: groups,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
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
                                child: Text(compact.format(v), style: Theme.of(context).textTheme.bodySmall),
                              ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            DateFormat.MMM(lang(context)).format(months[v.toInt()]),
                            style: months[v.toInt()] == selected
                                ? Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)
                                : Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      final spot = response?.spot;
                      if (event is FlTapUpEvent && spot != null) onSelect(months[spot.touchedBarGroupIndex]);
                    },
                    mouseCursorResolver: (_, response) =>
                        response?.spot == null ? MouseCursor.defer : SystemMouseCursors.click,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => scheme.inverseSurface,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, _, rod, _) {
                        final m = months[group.x];
                        final byGroup = values[_ym(m)] ?? const {};
                        final lines = [
                          for (final s in series)
                            if ((byGroup[s] ?? 0) > 0) '${seriesName(s)}  ${money(context, byGroup[s]!, currency)}',
                        ];
                        return BarTooltipItem(
                          '${monthLabel(context, m)}\n${money(context, (rod.toY * 100).round(), currency)}\n',
                          TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.left,
                          children: [
                            TextSpan(
                              text: lines.join('\n'),
                              style: TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.normal),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ranked amounts with a proportional bar.
class _RankedList extends StatelessWidget {
  const _RankedList({
    required this.title,
    required this.rows,
    required this.currency,
    this.colored = false,
    this.onTap,
  });

  /// Opens the lines behind a row.
  final void Function(Amount row)? onTap;

  final String title;
  final List<Amount> rows;
  final String currency;

  /// Rows are categories: show their group color and localized name.
  final bool colored;

  @override
  Widget build(BuildContext context) {
    final index = context.watch<CategoryIndex>();
    final t = Theme.of(context).textTheme;
    final top = rows.isEmpty ? 1 : rows.map((r) => r.cents).reduce(max).clamp(1, 1 << 40);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.titleMedium),
            const SizedBox(height: 12),
            if (rows.isEmpty) Text(AppLocalizations.of(context).noSpendingThisMonth, style: t.bodySmall),
            for (final r in rows)
              InkWell(
                onTap: onTap == null ? null : () => onTap!(r),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                  child: Row(
                    children: [
                      if (colored) ...[
                        CircleAvatar(radius: 5, backgroundColor: groupColor(context, r.key.isEmpty ? null : r.key)),
                        const SizedBox(width: 8),
                      ],
                      SizedBox(
                        width: 200,
                        child: Text(
                          colored ? index.name(context, r.key.isEmpty ? null : r.key) : r.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) => Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 8,
                              width: c.maxWidth * (r.cents.clamp(0, top) / top),
                              decoration: BoxDecoration(
                                color: colored
                                    ? groupColor(context, r.key.isEmpty ? null : r.key)
                                    : Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        child: Text(money(context, r.cents, currency), textAlign: TextAlign.right, style: t.bodyMedium),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('${r.count}', textAlign: TextAlign.right, style: t.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact target progress for the selected month's reference day. Hidden
/// when the scope has no targets.
class _TargetsCard extends StatelessWidget {
  const _TargetsCard(this.scope, this.reference, this.currency);

  final Scope scope;
  final DateTime reference;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final repo = context.read<ExpenseRepository>();
    final (from, to) = linesWindow(reference);
    return KeyedStreamBuilder<List<TargetRow>>(
      streamKey: scope,
      stream: () => repo.watchTargets(scope),
      builder: (context, targets) {
        if (targets == null || targets.isEmpty) return const SizedBox.shrink();
        return KeyedStreamBuilder<List<(DateTime, String?, int)>>(
          streamKey: (scope, from),
          stream: () => repo.watchSpendingLines(scope, from, to),
          builder: (context, lines) {
            final views = computeTargets(targets, lines ?? const [], reference, DateTime.now());
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.navTargets, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final v in views)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 260,
                              child: Text(
                                '${targetName(context, index, v.row.categoryId)} · ${periodLabel(l, v.period)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(child: TargetBar(v.progress)),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 220,
                              child: Text(
                                l.targetSpent(
                                  money(context, v.progress.spent, currency),
                                  money(context, v.progress.target, currency),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(width: 140, child: StatusChip(v.progress.status)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Shown when the selected month has no transactions (typically the current
/// month, before its statements exist), with a shortcut to the latest month.
class _EmptyMonth extends StatelessWidget {
  const _EmptyMonth(this.month);

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<DateTime?>(
      future: context.read<ExpenseRepository>().latestTransactionDate(),
      builder: (context, snap) {
        final latest = snap.data;
        return Card(
          color: scheme.secondaryContainer,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(child: Text(l.emptyMonth(monthLabel(context, month)))),
                if (latest != null && latest.isBefore(month))
                  FilledButton.tonal(
                    onPressed: () => context.read<AppState>().month = latest,
                    child: Text(l.goToMonth(monthLabel(context, DateTime.utc(latest.year, latest.month)))),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
