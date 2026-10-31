import 'dart:io';

import 'package:banks/banks.dart' show bankFor;
import 'package:core/core.dart' show TransactionKind;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../app_state.dart';
import '../export.dart';
import '../l10n/app_localizations.dart';
import '../style.dart';
import '../widgets/category_chip.dart';
import '../widgets/keyed_stream.dart';
import '../widgets/split_editor.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _search = '';
  String? _category;
  int? _account;
  bool _allDates = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final index = context.watch<CategoryIndex>();
    final repo = context.read<ExpenseRepository>();
    final scope = state.scope;
    if (scope == null) return Center(child: Text(l.noData));
    final filter = TxnFilter(
      scope: scope,
      from: _allDates ? null : state.month,
      to: _allDates ? null : state.nextMonth,
      accountId: _account,
      categoryId: _category,
      search: _search,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          // Wraps onto a second line on narrow windows instead of overflowing.
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.search, isDense: true),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              DropdownButton<String?>(
                value: _category,
                hint: Text(l.allCategories),
                onChanged: (v) => setState(() => _category = v),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.allCategories)),
                  for (final g in index.groups) ...[
                    DropdownMenuItem(
                      value: g.id,
                      child: Text(index.name(context, g.id), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    for (final c in index.childrenOf(g.id))
                      DropdownMenuItem(value: c.id, child: Text('    ${index.name(context, c.id)}')),
                  ],
                ],
              ),
              StreamBuilder<List<Account>>(
                stream: repo.watchAccounts(),
                builder: (context, snap) {
                  final accounts = (snap.data ?? const <Account>[])
                      .where(
                        (a) =>
                            a.institution == scope.institution &&
                            (scope.currency == null || a.currency == scope.currency),
                      )
                      .toList();
                  return DropdownButton<int?>(
                    value: accounts.any((a) => a.id == _account) ? _account : null,
                    hint: Text(l.allAccounts),
                    onChanged: (v) => setState(() => _account = v),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.allAccounts)),
                      for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(accountName(a))),
                    ],
                  );
                },
              ),
              FilterChip(
                label: Text(l.allDates),
                selected: _allDates,
                onSelected: (v) => setState(() => _allDates = v),
              ),
              Tooltip(
                message: l.exportHint,
                child: FilledButton.tonalIcon(
                  onPressed: () => _export(context, filter),
                  icon: const Icon(Icons.file_download_outlined),
                  label: Text(l.exportTransactions),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: KeyedStreamBuilder<List<TxnView>>(
            streamKey: (scope, filter.from, _allDates, _account, _category, _search),
            stream: () => repo.watchTransactions(filter),
            builder: (context, rows) {
              final list = rows ?? const <TxnView>[];
              return Column(
                children: [
                  _Header(l),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) => _Row(list[i]),
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

extension on _TransactionsScreenState {
  /// Exactly what the page shows (bank or account, month or all dates,
  /// category, search) to an Excel or CSV file the user picks.
  Future<void> _export(BuildContext context, TxnFilter filter) async {
    final l = AppLocalizations.of(context);
    final index = context.read<CategoryIndex>();
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final language = lang(context);
    final views = await context.read<ExpenseRepository>().watchTransactions(filter).first;
    final month = '${state.month.year}-${state.month.month.toString().padLeft(2, '0')}';
    final location = await getSaveLocation(
      suggestedName: '${l.exportFileName}-${filter.scope!.institution}-${_allDates ? l.allDates : month}.xlsx'
          .replaceAll(' ', '-')
          .toLowerCase(),
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Excel', extensions: ['xlsx']),
        XTypeGroup(label: 'CSV', extensions: ['csv']),
      ],
    );
    if (location == null || !context.mounted) return;
    var path = location.path;
    if (!path.toLowerCase().endsWith('.xlsx') && !path.toLowerCase().endsWith('.csv')) {
      path += location.activeFilter?.label == 'CSV' ? '.csv' : '.xlsx';
    }
    final rows = exportRows(
      views,
      ExportNames(
        bank: (institution) => bankFor(institution)?.displayName ?? institution,
        account: (a) => a.type == 'cash' ? scopeLabel(context, Scope('cash', currency: a.currency)) : accountName(a),
        group: (id) => id == null || id.isEmpty ? '' : index.name(context, groupOf(id)),
        category: (id) => index.name(context, id == null || id.isEmpty ? null : id),
        type: (kind) => kindLabel(l, kind),
      ),
    );
    final headers = [
      l.colDate,
      l.hdrBank,
      l.colAccount,
      l.colMerchant,
      l.hdrDescription,
      l.hdrGroup,
      l.colCategory,
      l.hdrType,
      l.colAmount,
      l.hdrCurrency,
      l.hdrForeignAmount,
      l.hdrForeignCurrency,
      l.hdrNote,
    ];
    final bytes = path.toLowerCase().endsWith('.csv')
        ? csvBytes(toCsv(rows, headers, languageCode: language, splitWord: l.splitPart))
        : toXlsx(rows, headers, sheetName: l.navTransactions, splitWord: l.splitPart);
    await File(path).writeAsBytes(bytes);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${l.exportedLines(rows.length)} — $path'),
        action: SnackBarAction(label: l.openFile, onPressed: () => Process.run('cmd', ['/c', 'start', '', path])),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.l);

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelMedium;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(l.colDate, style: s)),
          SizedBox(width: 170, child: Text(l.colAccount, style: s)),
          Expanded(child: Text(l.colMerchant, style: s)),
          SizedBox(width: 240, child: Text(l.colCategory, style: s)),
          SizedBox(
            width: 120,
            child: Text(l.colAmount, style: s, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.v);

  final TxnView v;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final kind = TransactionKind.values.byName(v.txn.kind);
    final counted = kind.countsAsSpending || kind.countsAsIncome;
    return InkWell(
      onTap: () => showTransactionDetails(context, v),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(shortDate(context, v.txn.date))),
            SizedBox(
              width: 170,
              child: Text(
                v.account.name,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(color: muted),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.displayName, overflow: TextOverflow.ellipsis),
                  Text(
                    [v.txn.description, if (v.txn.location != null) v.txn.location].join(' · '),
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 240,
              child: Align(alignment: Alignment.centerLeft, child: CategoryChip(v)),
            ),
            SizedBox(
              width: 120,
              child: Text(
                money(context, v.txn.amount, v.account.currency),
                textAlign: TextAlign.right,
                style: t.bodyMedium?.copyWith(
                  color: counted ? null : muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything known about a transaction; edit kind and note.
Future<void> showTransactionDetails(BuildContext context, TxnView v) => showDialog(
  context: context,
  builder: (context) {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final t = v.txn;
    final note = TextEditingController(text: t.note);
    Widget field(String label, String? value) => value == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 150, child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
                Expanded(child: SelectableText(value)),
              ],
            ),
          );
    return AlertDialog(
      title: Text(v.displayName),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(money(context, t.amount, v.account.currency), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            field(l.date, shortDate(context, t.date)),
            field(l.colAccount, v.account.name),
            field(l.statementText, [t.code, t.description].whereType<String>().join(' · ')),
            field(l.location, t.location),
            field(l.card, t.card),
            if (t.foreignCents != null)
              field(
                l.originalAmount,
                '${money(context, t.foreignCents!, t.foreignCurrency ?? '')} @ ${t.fxRate ?? ''}',
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 150, child: Text(l.kind, style: Theme.of(context).textTheme.labelMedium)),
                DropdownButton<TransactionKind>(
                  value: TransactionKind.values.byName(t.kind),
                  onChanged: (k) {
                    if (k != null) repo.setKind(t.id, k);
                    Navigator.pop(context);
                  },
                  items: [
                    for (final k in TransactionKind.values)
                      DropdownMenuItem(value: k, child: Text(kindLabel(l, k.name))),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 150, child: Text(l.colCategory, style: Theme.of(context).textTheme.labelMedium)),
                CategoryChip(v),
                const SizedBox(width: 8),
                if (TransactionKind.values.byName(t.kind).countsAsSpending)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showSplitEditor(context, v);
                    },
                    icon: const Icon(Icons.call_split),
                    label: Text(l.split),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: l.note),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            repo.setNote(t.id, note.text.trim().isEmpty ? null : note.text.trim());
            Navigator.pop(context);
          },
          child: Text(l.save),
        ),
      ],
    );
  },
);
