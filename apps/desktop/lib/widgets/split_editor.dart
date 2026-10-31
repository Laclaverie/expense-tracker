import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import '../style.dart';
import 'category_picker.dart';

/// Splits a transaction across categories (e.g. Costco: groceries +
/// household). Parts must add up to the transaction amount before saving.
Future<void> showSplitEditor(BuildContext context, TxnView view) =>
    showDialog(context: context, builder: (_) => _SplitEditor(view));

class _Part {
  _Part(this.categoryId, int cents) : amount = TextEditingController(text: cents == 0 ? '' : _format(cents));

  String? categoryId;
  final TextEditingController amount;

  int get cents {
    final v = double.tryParse(amount.text.replaceAll(',', '.').replaceAll(' ', ''));
    return v == null ? 0 : (v * 100).round();
  }

  static String _format(int cents) => (cents / 100).toStringAsFixed(2);
}

class _SplitEditor extends StatefulWidget {
  const _SplitEditor(this.view);

  final TxnView view;

  @override
  State<_SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends State<_SplitEditor> {
  late final int _total = widget.view.txn.amount.abs();
  late final List<_Part> _parts = widget.view.isSplit
      ? [for (final s in widget.view.splits) _Part(s.categoryId, s.amount.abs())]
      : [_Part(widget.view.txn.categoryId, _total), _Part(null, 0)];

  int get _remaining => _total - _parts.fold(0, (s, p) => s + p.cents);

  bool get _valid =>
      _parts.length >= 2 &&
      _remaining == 0 &&
      _parts.every((p) => p.categoryId != null && p.categoryId!.contains('.') && p.cents > 0);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final currency = widget.view.account.currency;
    final repo = context.read<ExpenseRepository>();
    return AlertDialog(
      title: Text('${l.splitTitle} — ${money(context, widget.view.txn.amount, currency)}'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.view.displayName, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final (i, part) in _parts.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: CircleAvatar(radius: 5, backgroundColor: groupColor(context, part.categoryId)),
                        label: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            part.categoryId == null ? l.chooseCategory : index.name(context, part.categoryId),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onPressed: () async {
                          final picked = await pickCategory(context, current: part.categoryId);
                          if (picked != null) setState(() => part.categoryId = picked.categoryId);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: part.amount,
                        textAlign: TextAlign.right,
                        onTap: () =>
                            part.amount.selection = TextSelection(baseOffset: 0, extentOffset: part.amount.text.length),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        decoration: InputDecoration(isDense: true, suffixText: currency == 'EUR' ? '€' : '\$'),
                        onChanged: (_) => setState(() {
                          // Two parts: the other one takes the remainder.
                          if (_parts.length == 2) {
                            final other = _parts[1 - i];
                            final rest = _total - part.cents;
                            other.amount.text = rest > 0 ? (rest / 100).toStringAsFixed(2) : '';
                          }
                        }),
                      ),
                    ),
                    IconButton(
                      tooltip: l.delete,
                      onPressed: _parts.length <= 2 ? null : () => setState(() => _parts.removeAt(i)),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _parts.add(_Part(null, _remaining > 0 ? _remaining : 0))),
                  icon: const Icon(Icons.add),
                  label: Text(l.splitAddPart),
                ),
                const Spacer(),
                Text(
                  l.splitRemaining(money(context, _remaining, currency)),
                  style: TextStyle(
                    color: _remaining == 0 ? null : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.view.isSplit)
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await repo.setSplits(widget.view.txn.id, const []);
              navigator.pop();
            },
            child: Text(l.splitRemove),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: !_valid
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  await repo.setSplits(widget.view.txn.id, [for (final p in _parts) (p.categoryId!, p.cents)]);
                  navigator.pop();
                },
          child: Text(l.save),
        ),
      ],
    );
  }
}
