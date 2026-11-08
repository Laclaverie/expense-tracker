import 'package:core/core.dart' show DayRange, appNow;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../keyed_stream.dart';
import '../l10n/app_localizations.dart';
import '../phone_store.dart';
import '../session.dart';
import '../state.dart';
import '../style.dart';
import '../sync_banner.dart';
import 'transactions.dart';

String _ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// This month against last month, targets, the latest transactions and the age of the data.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.session, required this.check, this.onSeeAll});

  final Session session;
  final Future<Offer?> Function() check;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scope = context.watch<PhoneState>().scope;
    final date = session.store.dataDate();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        SyncBanner(session: session, check: check),
        if (scope == null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l.noData, textAlign: TextAlign.center),
          )
        else ...[
          const SizedBox(height: 8),
          _MonthCard(scope),
          const SizedBox(height: 12),
          _TargetsCard(scope.whole),
          const SizedBox(height: 12),
          _Recent(scope, onSeeAll),
        ],
        if (date != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              l.dataFrom(date.toLocal()),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

/// Spent this month and last month. A month missing a statement says so instead of showing 0.
class _MonthCard extends StatelessWidget {
  const _MonthCard(this.scope);

  final Scope scope;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final now = appNow();
    final month = DateTime.utc(now.year, now.month);
    final previous = DateTime.utc(now.year, now.month - 1);
    final next = DateTime.utc(now.year, now.month + 1);
    final currency = scopeCurrency(scope);
    return KeyedStreamBuilder<List<(String, int, int)>>(
      streamKey: (scope, month),
      stream: () => repo.watchMonthlyTotals(scope, previous, next),
      builder: (context, totals) => KeyedStreamBuilder<Map<String, List<DayRange>>>(
        streamKey: scope,
        stream: () => repo.watchCoverage(scope),
        builder: (context, coverage) {
          if (totals == null || coverage == null) return const SizedBox(height: 120);
          final statuses = monthStatuses(coverage, [previous, month]);
          final (prev, cur) = (statuses[0], statuses[1]);
          int? spentOf(DateTime m) => totals.where((t) => t.$1 == _ym(m)).map((t) => t.$2).firstOrNull;
          final curSpent = spentOf(month), prevSpent = spentOf(previous);
          final curMissing = curSpent == null && !cur.complete;
          final prevMissing = prevSpent == null && !prev.complete;
          // Only complete months compare: a month missing a statement looks cheap.
          String? delta;
          if (cur.complete && prev.complete && prevSpent != null && prevSpent > 0) {
            final pct = ((curSpent ?? 0) - prevSpent) / prevSpent * 100;
            delta = l.vsLastMonth('${pct >= 0 ? '+' : ''}${pct.round()} %');
          }
          final t = Theme.of(context).textTheme;
          final muted = t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
          final prevText = prevMissing
              ? l.statementMissing
              : '${money(context, prevSpent ?? 0, currency)}${prev.complete ? '' : ' · ${l.incomplete}'}';
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.spentIn(monthLabel(context, month)), style: t.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    curMissing ? l.statementMissing : money(context, curSpent ?? 0, currency),
                    style: curMissing ? t.titleLarge : t.headlineMedium,
                  ),
                  if (!cur.complete && !curMissing) Text(l.incomplete, style: muted),
                  if (delta != null) Text(delta, style: muted),
                  const SizedBox(height: 8),
                  Text(l.lastMonthIs(monthLabel(context, previous), prevText), style: muted),
                  if (!cur.complete || !prev.complete) _GapAccounts(scope, [previous, month]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Names the accounts whose statements miss part of [months] (account names, not bank labels).
class _GapAccounts extends StatefulWidget {
  const _GapAccounts(this.scope, this.months);

  final Scope scope;
  final List<DateTime> months;

  @override
  State<_GapAccounts> createState() => _GapAccountsState();
}

class _GapAccountsState extends State<_GapAccounts> {
  late Future<List<String>> _names = _load();

  @override
  void didUpdateWidget(_GapAccounts old) {
    super.didUpdateWidget(old);
    if (old.scope != widget.scope) _names = _load();
  }

  Future<List<String>> _load() async {
    final repo = context.read<ExpenseRepository>();
    final scope = widget.scope;
    final accounts = (await repo.watchAccounts().first).where(
      (a) =>
          a.institution == scope.institution &&
          a.currency == scope.currency &&
          (scope.accountId == null || a.id == scope.accountId),
    );
    final names = <String>[];
    for (final a in accounts) {
      final coverage = await repo.watchCoverage(scope.withAccount(a.id)).first;
      if (monthStatuses(coverage, widget.months).any((s) => !s.complete)) names.add(accountName(a));
    }
    return names;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<String>>(
    future: _names,
    builder: (context, snap) {
      final names = snap.data;
      if (names == null || names.isEmpty) return const SizedBox.shrink();
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(AppLocalizations.of(context).coverageWarning(names.join(', ')))),
          ],
        ),
      );
    },
  );
}

/// Target progress for today's week, month and year. Hidden when the scope has no targets.
class _TargetsCard extends StatelessWidget {
  const _TargetsCard(this.scope);

  final Scope scope;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final repo = context.read<ExpenseRepository>();
    final now = appNow();
    final today = DateTime.utc(now.year, now.month, now.day);
    final (from, to) = linesWindow(today);
    final currency = scopeCurrency(scope);
    return KeyedStreamBuilder<List<TargetRow>>(
      streamKey: scope,
      stream: () => repo.watchTargets(scope),
      builder: (context, targets) {
        if (targets == null || targets.isEmpty) return const SizedBox.shrink();
        return KeyedStreamBuilder<List<(DateTime, String?, int)>>(
          streamKey: (scope, from),
          stream: () => repo.watchSpendingLines(scope, from, to),
          builder: (context, lines) {
            final views = computeTargets(targets, lines ?? const [], today, now);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.targetsTitle, style: Theme.of(context).textTheme.titleMedium),
                    for (final v in views)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${v.row.categoryId == null ? l.allSpending : index.name(context, v.row.categoryId)}'
                              ' · ${periodLabel(l, v.period)}',
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: v.progress.ratio.clamp(0, 1).toDouble(),
                                minHeight: 8,
                                color: statusColor(v.progress.status),
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 12,
                              children: [
                                Text(
                                  l.targetSpent(
                                    money(context, v.progress.spent, currency),
                                    money(context, v.progress.target, currency),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon(v.progress.status),
                                      color: statusColor(v.progress.status),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(statusLabel(l, v.progress.status)),
                                  ],
                                ),
                              ],
                            ),
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

/// The ten latest transactions of the scope.
class _Recent extends StatelessWidget {
  const _Recent(this.scope, this.onSeeAll);

  final Scope scope;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    return KeyedStreamBuilder<DateTime?>(
      streamKey: scope,
      stream: () => repo.watchLatestDate(scope),
      builder: (context, latest) {
        if (latest == null) return const SizedBox.shrink();
        final from = DateTime.utc(latest.year, latest.month - 2);
        return KeyedStreamBuilder<List<TxnView>>(
          streamKey: (scope, from),
          stream: () => repo.watchTransactions(TxnFilter(scope: scope, from: from)),
          builder: (context, rows) {
            final list = (rows ?? const <TxnView>[]).take(10).toList();
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                      child: Row(
                        children: [
                          Expanded(child: Text(l.recentTransactions, style: Theme.of(context).textTheme.titleMedium)),
                          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: Text(l.seeAll)),
                        ],
                      ),
                    ),
                    if (list.isEmpty)
                      Padding(padding: const EdgeInsets.all(16), child: Text(l.noTransactions))
                    else
                      for (final v in list) TransactionTile(v, showDate: true),
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
