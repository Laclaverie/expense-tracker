import 'package:core/core.dart' show TransactionKind, appNow;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../keyed_stream.dart';
import '../l10n/app_localizations.dart';
import '../state.dart';
import '../style.dart';

/// Transactions of the scope grouped by day: search, filters (account, category, month), tap for details.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _search = '';
  String? _category;
  int? _account;
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scope = context.watch<PhoneState>().scope;
    if (scope == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.noData, textAlign: TextAlign.center),
        ),
      );
    }
    final index = context.watch<CategoryIndex>();
    final repo = context.read<ExpenseRepository>();
    final account = scope.accountId ?? _account;
    final filter = TxnFilter(
      scope: scope,
      from: _month,
      to: _month == null ? null : DateTime.utc(_month!.year, _month!.month + 1),
      accountId: account,
      categoryId: _category,
      search: _search,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.search,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 8,
            children: [
              if (scope.accountId == null)
                StreamBuilder<List<Account>>(
                  stream: repo.watchAccounts(),
                  builder: (context, snap) {
                    final accounts = [
                      for (final a in snap.data ?? const <Account>[])
                        if (a.institution == scope.institution && a.currency == scope.currency) a,
                    ];
                    if (accounts.length < 2) return const SizedBox.shrink();
                    final chosen = accounts.where((a) => a.id == _account).firstOrNull;
                    return _FilterChip(
                      label: chosen == null ? l.allAccounts : accountName(chosen),
                      active: chosen != null,
                      onTap: () async {
                        final picked = await _pick<int?>(context, l.colAccount, [
                          (l.allAccounts, null),
                          for (final a in accounts) (accountName(a), a.id),
                        ]);
                        if (picked != null) setState(() => _account = picked.$1);
                      },
                    );
                  },
                ),
              _FilterChip(
                label: _category == null ? l.allCategories : index.name(context, _category),
                active: _category != null,
                onTap: () async {
                  final picked = await _pick<String?>(context, l.colCategory, [
                    (l.allCategories, null),
                    for (final g in index.groups) ...[
                      (index.name(context, g.id), g.id),
                      for (final c in index.childrenOf(g.id)) ('    ${index.name(context, c.id)}', c.id),
                    ],
                  ]);
                  if (picked != null) setState(() => _category = picked.$1);
                },
              ),
              _FilterChip(
                label: _month == null ? l.allDates : monthLabel(context, _month!),
                active: _month != null,
                onTap: () async {
                  final now = appNow();
                  final picked = await _pick<DateTime?>(context, l.colDate, [
                    (l.allDates, null),
                    for (var i = 0; i < 24; i++)
                      (
                        monthLabel(context, DateTime.utc(now.year, now.month - i)),
                        DateTime.utc(now.year, now.month - i),
                      ),
                  ]);
                  if (picked != null) setState(() => _month = picked.$1);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 8),
        Expanded(
          child: KeyedStreamBuilder<List<TxnView>>(
            streamKey: (scope, _month, account, _category, _search),
            stream: () => repo.watchTransactions(filter),
            builder: (context, rows) {
              final list = rows ?? const <TxnView>[];
              if (rows != null && list.isEmpty) return Center(child: Text(l.noTransactions));
              final items = <Object>[];
              DateTime? day;
              for (final v in list) {
                if (day != v.txn.date) {
                  day = v.txn.date;
                  items.add(day);
                }
                items.add(v);
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) => switch (items[i]) {
                        final DateTime d => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(longDate(context, d), style: Theme.of(context).textTheme.labelLarge),
                        ),
                        final TxnView v => TransactionTile(v),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(l.transactionCount(list.length), style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Text(label.trim(), overflow: TextOverflow.ellipsis),
    ),
    avatar: active ? const Icon(Icons.check, size: 16) : null,
    onPressed: onTap,
  );
}

/// A bottom sheet with one choice per row; null when dismissed. The value is wrapped so that choosing
/// "all" (a null value) differs from dismissing.
Future<(T,)?> _pick<T>(BuildContext context, String title, List<(String, T)> options) => showModalBottomSheet<(T,)>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    maxChildSize: 0.9,
    builder: (context, controller) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: ListView(
            controller: controller,
            children: [
              for (final (label, value) in options)
                ListTile(
                  dense: true,
                  title: Text(
                    label,
                    style: label.startsWith(' ') ? null : const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(context, (value,)),
                ),
            ],
          ),
        ),
      ],
    ),
  ),
);

/// One transaction: merchant, account and category, amount. Tap opens the read-only details.
class TransactionTile extends StatelessWidget {
  const TransactionTile(this.view, {super.key, this.showDate = false, this.part});

  final TxnView view;
  final bool showDate;

  /// One part of a split transaction (its category and amount) instead of the whole.
  final (String categoryId, int amount)? part;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final index = context.watch<CategoryIndex>();
    final kind = TransactionKind.values.byName(view.txn.kind);
    final counted = kind.countsAsSpending || kind.countsAsIncome;
    final category = part != null
        ? index.name(context, part!.$1)
        : view.isSplit
        ? AppLocalizations.of(context).splitParts
        : index.name(context, view.txn.categoryId);
    return ListTile(
      dense: true,
      leading: CircleAvatar(radius: 6, backgroundColor: groupColor(context, part?.$1 ?? view.txn.categoryId)),
      title: Text(view.displayName, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [if (showDate) shortDate(context, view.txn.date), category, accountName(view.account)].join(' · '),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        money(context, part?.$2 ?? view.txn.amount, view.account.currency),
        style: t.bodyMedium?.copyWith(
          color: counted ? null : muted,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      onTap: () => showTransactionDetails(context, view),
    );
  }
}

/// Everything known about a transaction, read only.
Future<void> showTransactionDetails(BuildContext context, TxnView v) {
  // Read here: the sheet can rebuild while the page under it is going away (a lock).
  final index = context.read<CategoryIndex>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) {
      final l = AppLocalizations.of(sheet);
      final t = v.txn;
      final kind = TransactionKind.values.byName(t.kind);
      Widget field(String label, String? value) => value == null || value.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 110, child: Text(label, style: Theme.of(sheet).textTheme.labelMedium)),
                  Expanded(child: SelectableText(value)),
                ],
              ),
            );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(v.displayName, style: Theme.of(sheet).textTheme.titleLarge),
              Text(money(sheet, t.amount, v.account.currency), style: Theme.of(sheet).textTheme.headlineSmall),
              const SizedBox(height: 12),
              field(l.colDate, longDate(sheet, t.date)),
              field(l.colAccount, v.account.name),
              field(l.statementText, [t.code, t.description].whereType<String>().join(' · ')),
              field(l.location, t.location),
              field(l.card, t.card),
              if (t.foreignCents != null)
                field(
                  l.originalAmount,
                  '${money(sheet, t.foreignCents!, t.foreignCurrency ?? '')}${t.fxRate == null ? '' : ' @ ${t.fxRate}'}',
                ),
              field(l.kind, kindLabel(l, t.kind)),
              if (v.isSplit)
                for (final s in v.splits)
                  field(
                    l.colCategory,
                    '${index.name(sheet, s.categoryId)} · ${money(sheet, s.amount, v.account.currency)}',
                  )
              else
                field(l.colCategory, index.name(sheet, t.categoryId)),
              field(l.note, t.note),
              if (!(kind.countsAsSpending || kind.countsAsIncome))
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.notCounted)),
            ],
          ),
        ),
      );
    },
  );
}
