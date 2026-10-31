import 'package:core/core.dart' show TransactionKind, targetCovers;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import '../style.dart';
import '../screens/transactions.dart' show showTransactionDetails;
import 'category_chip.dart';

/// Spending lines behind a figure (a category or merchant total), with the
/// count and total on top. For a split transaction, only the part in
/// [categoryId] is counted. Click a line to open it.
class SpendingList extends StatelessWidget {
  const SpendingList({super.key, required this.filter, this.uncategorizedOnly = false});

  final TxnFilter filter;

  /// Lines without any category (the "Uncategorized" figure).
  final bool uncategorizedOnly;

  /// Cents spent by [v] that belong to the filtered category (positive = spent).
  int _spent(TxnView v) {
    final category = filter.categoryId;
    if (category != null && v.isSplit) {
      return -v.splits.where((s) => targetCovers(category, s.categoryId)).fold(0, (sum, s) => sum + s.amount);
    }
    return -v.txn.amount;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return StreamBuilder<List<TxnView>>(
      stream: context.read<ExpenseRepository>().watchTransactions(filter),
      builder: (context, snap) {
        final rows = (snap.data ?? const <TxnView>[])
            .where((v) => TransactionKind.values.byName(v.txn.kind).countsAsSpending)
            .where((v) => !uncategorizedOnly || (v.txn.categoryId == null && !v.isSplit))
            .toList();
        final total = rows.fold(0, (s, v) => s + _spent(v));
        final currency = rows.isEmpty ? 'CAD' : rows.first.account.currency;
        final t = Theme.of(context).textTheme;
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l.transactionCount(rows.length)} · ${money(context, total, currency)}', style: t.titleSmall),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final v = rows[i];
                  final spent = _spent(v);
                  return InkWell(
                    onTap: () => showTransactionDetails(context, v),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(width: 70, child: Text(shortDate(context, v.txn.date))),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.displayName, overflow: TextOverflow.ellipsis),
                                Text(
                                  [v.txn.description, v.txn.location, v.account.name].whereType<String>().join(' · '),
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall?.copyWith(color: muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 220,
                            child: Align(alignment: Alignment.centerLeft, child: CategoryChip(v)),
                          ),
                          SizedBox(
                            width: 130,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(money(context, -spent, v.account.currency)),
                                if (spent != -v.txn.amount)
                                  Text(
                                    l.partOf(money(context, v.txn.amount, v.account.currency)),
                                    style: t.bodySmall?.copyWith(color: muted),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dialog with the spending lines behind a figure.
Future<void> showSpendingDialog(
  BuildContext context, {
  required String title,
  required TxnFilter filter,
  bool uncategorizedOnly = false,
  Widget? header,
}) => showDialog(
  context: context,
  builder: (c) => AlertDialog(
    title: Text(title),
    content: SizedBox(
      width: 900,
      height: header == null ? 560 : 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?header,
          Expanded(
            child: SpendingList(filter: filter, uncategorizedOnly: uncategorizedOnly),
          ),
        ],
      ),
    ),
    actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(AppLocalizations.of(c).close))],
  ),
);
