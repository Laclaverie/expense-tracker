import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart' show appNow;
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import '../style.dart';
import '../widgets/category_picker.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    return StreamBuilder<Map<int, int>>(
      stream: repo.watchAccountTotals(),
      builder: (context, totals) => StreamBuilder<List<Account>>(
        stream: repo.watchAccounts(),
        builder: (context, snap) {
          final accounts = snap.data ?? const <Account>[];
          // Cash wallets have no statements: their balance is the sum of their entries.
          int? balance(Account a) => a.type == 'cash' ? (totals.data?[a.id] ?? 0) : a.balance;
          final byInstitution = <String, List<Account>>{};
          for (final a in accounts) {
            byInstitution.putIfAbsent(a.institution, () => []).add(a);
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Text(l.navAccounts, style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => showCashExpenseDialog(context),
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(l.addCashExpense),
                  ),
                ],
              ),
              if (accounts.isEmpty) Padding(padding: const EdgeInsets.only(top: 24), child: Text(l.noData)),
              for (final MapEntry(key: institution, value: list) in byInstitution.entries) ...[
                const SizedBox(height: 16),
                Text(
                  scopeLabel(context, Scope(institution, currency: institution == 'cash' ? '' : null)).trim(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final a in list)
                      SizedBox(
                        width: 300,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(accountIcon(a.type), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        a.type == 'cash'
                                            ? scopeLabel(context, Scope('cash', currency: a.currency))
                                            : a.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (a.type != 'cash')
                                      Text(
                                        a.ref.startsWith('card-') ? '•••• ${a.ref.substring(5)}' : a.ref,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  balance(a) == null ? '—' : money(context, balance(a)!, a.currency),
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                if (a.balanceDate != null)
                                  Text(
                                    l.balanceAsOf(DateFormat.yMMMd(lang(context)).format(a.balanceDate!)),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Manual expense in a cash wallet (CAD or EUR).
Future<void> showCashExpenseDialog(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _CashExpenseDialog());

class _CashExpenseDialog extends StatefulWidget {
  const _CashExpenseDialog();

  @override
  State<_CashExpenseDialog> createState() => _CashExpenseDialogState();
}

class _CashExpenseDialogState extends State<_CashExpenseDialog> {
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _note = TextEditingController();
  String _currency = 'CAD';
  String? _category;
  DateTime _date = appNow();

  int? get _cents {
    final v = double.tryParse(_amount.text.replaceAll(',', '.').replaceAll(' ', ''));
    return v == null || v <= 0 ? null : (v * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    return AlertDialog(
      title: Text(l.addCashExpense),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    decoration: InputDecoration(labelText: l.amount),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'CAD', label: Text('CAD')),
                    ButtonSegment(value: 'EUR', label: Text('EUR')),
                  ],
                  selected: {_currency},
                  onSelectionChanged: (s) => setState(() => _currency = s.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: CircleAvatar(radius: 5, backgroundColor: groupColor(context, _category)),
                    label: Text(_category == null ? l.chooseCategory : index.name(context, _category)),
                    onPressed: () async {
                      final picked = await pickCategory(context, current: _category);
                      if (picked != null) setState(() => _category = picked.categoryId);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(shortDate(context, _date)),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: appNow().add(const Duration(days: 1)),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),
              ],
            ),
            TextField(
              controller: _merchant,
              decoration: InputDecoration(labelText: l.merchantOptional),
            ),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: l.note),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: _cents == null || _category == null
              ? null
              : () async {
                  final importer = context.read<ImportService>();
                  final repo = context.read<ExpenseRepository>();
                  final navigator = Navigator.of(context);
                  final wallet = await importer.cashWallet(_currency);
                  await repo.addManual(
                    accountId: wallet,
                    date: DateTime.utc(_date.year, _date.month, _date.day),
                    amount: _cents!,
                    categoryId: _category!,
                    merchantName: _merchant.text,
                    note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                  );
                  navigator.pop();
                },
          child: Text(l.save),
        ),
      ],
    );
  }
}
