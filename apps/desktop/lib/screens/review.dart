import 'package:core/core.dart' show CategoryClassifier, ClassifierGuess, matchedKeyword;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../style.dart';
import '../widgets/category_chip.dart';
import '../widgets/category_picker.dart';
import '../widgets/keyed_stream.dart';

enum ReviewSort { date, amount, merchant }

/// Transactions whose category the app wasn't sure about, in every month of
/// the selected scope. Confirm or pick another; the choice can be remembered
/// for the merchant, which also clears its other lines from this queue.
/// Several lines can be selected and given one category, or confirmed, after
/// a confirmation: nothing leaves the queue without a click.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  ReviewSort _sort = ReviewSort.date;
  final _selected = <String>{};

  /// Lines under this amount (cents) are "small" for bulk selection.
  static const _small = 500;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scope = context.watch<AppState>().scope;
    final repo = context.read<ExpenseRepository>();
    if (scope == null) return Center(child: Text(l.noData));
    return KeyedStreamBuilder<List<TxnView>>(
      streamKey: scope,
      stream: () => repo.watchTransactions(TxnFilter(scope: scope, onlyReview: true)),
      builder: (context, rows) {
        final list = _sorted(rows ?? const <TxnView>[]);
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.task_alt, size: 48),
                const SizedBox(height: 12),
                Text(l.reviewEmpty, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }
        final selected = [
          for (final v in list)
            if (_selected.contains(v.txn.id)) v,
        ];
        final currency = list.first.account.currency;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text('${l.transactionCount(list.length)} — ${l.reviewHint}'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<ReviewSort>(
                    segments: [
                      ButtonSegment(value: ReviewSort.date, label: Text(l.sortDate)),
                      ButtonSegment(value: ReviewSort.amount, label: Text(l.sortAmount)),
                      ButtonSegment(value: ReviewSort.merchant, label: Text(l.sortMerchant)),
                    ],
                    selected: {_sort},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _sort = s.first),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _selected.addAll([
                        for (final v in list)
                          if (v.txn.amount.abs() < _small) v.txn.id,
                      ]),
                    ),
                    icon: const Icon(Icons.checklist),
                    label: Text(l.selectUnder(money(context, _small, currency))),
                  ),
                  if (selected.isNotEmpty) ...[
                    InputChip(
                      label: Text(l.selectedCount(selected.length)),
                      onDeleted: () => setState(_selected.clear),
                      deleteButtonTooltipMessage: l.clearSelection,
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _bulkCategory(context, selected),
                      icon: const Icon(Icons.edit),
                      label: Text(l.chooseCategory),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _bulkConfirm(context, selected),
                      icon: const Icon(Icons.check),
                      label: Text(l.confirm),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final id = list[i].txn.id;
                  return _ReviewCard(
                    list[i],
                    selected: _selected.contains(id),
                    onSelected: (on) => setState(() => on ? _selected.add(id) : _selected.remove(id)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<TxnView> _sorted(List<TxnView> rows) {
    final list = [...rows];
    switch (_sort) {
      case ReviewSort.date:
        break; // newest first, as loaded
      case ReviewSort.amount:
        list.sort((a, b) => b.txn.amount.abs().compareTo(a.txn.amount.abs()));
      case ReviewSort.merchant:
        String key(TxnView v) => v.txn.merchantId?.toString() ?? v.txn.description;
        final counts = <String, int>{};
        for (final v in list) {
          counts[key(v)] = (counts[key(v)] ?? 0) + 1;
        }
        list.sort((a, b) {
          final byCount = counts[key(b)]!.compareTo(counts[key(a)]!);
          return byCount != 0 ? byCount : key(a).compareTo(key(b));
        });
    }
    return list;
  }

  /// One category for every selected line, after a confirmation.
  Future<void> _bulkCategory(BuildContext context, List<TxnView> selected) async {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final index = context.read<CategoryIndex>();
    final messenger = ScaffoldMessenger.of(context);
    final picked = await pickCategory(context);
    if (picked == null || !context.mounted) return;
    final ok = await _ask(context, l.bulkSetQuestion(index.name(context, picked.categoryId), selected.length));
    if (!ok) return;
    final count = await repo.setCategoryMany([for (final v in selected) v.txn.id], picked.categoryId);
    setState(_selected.clear);
    messenger.showSnackBar(SnackBar(content: Text(l.updatedCount(count))));
  }

  /// Accepts the suggestion of every selected line that has a precise one,
  /// after a confirmation; the others stay.
  Future<void> _bulkConfirm(BuildContext context, List<TxnView> selected) async {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final precise = [
      for (final v in selected)
        if (v.txn.categoryId?.contains('.') ?? false) v.txn.id,
    ];
    final skipped = selected.length - precise.length;
    final question = [
      l.bulkConfirmQuestion(precise.length),
      if (skipped > 0) l.bulkConfirmSkipped(skipped),
    ].join('\n\n');
    if (precise.isEmpty || !await _ask(context, question)) return;
    final count = await repo.confirmMany(precise);
    setState(() => _selected.removeAll(precise));
    messenger.showSnackBar(SnackBar(content: Text(l.updatedCount(count))));
  }

  Future<bool> _ask(BuildContext context, String question) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Text(question),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.confirm)),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard(this.v, {required this.selected, required this.onSelected});

  final TxnView v;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final category = v.txn.categoryId;
    final canConfirm = category != null && category.contains('.');
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Checkbox(value: selected, onChanged: (on) => onSelected(on ?? false)),
            SizedBox(width: 80, child: Text(shortDate(context, v.txn.date))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.displayName, style: t.titleSmall),
                  Text(
                    [v.txn.description, v.txn.location, v.account.name].whereType<String>().join(' · '),
                    style: t.bodySmall?.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                  _ReviewReason(v),
                  _Suggestions(v),
                ],
              ),
            ),
            IconButton(
              tooltip: l.copyForSearch,
              onPressed: () => _copyForSearch(context),
              icon: const Icon(Icons.content_copy, size: 18),
            ),
            SizedBox(
              width: 120,
              child: Text(money(context, v.txn.amount, v.account.currency), textAlign: TextAlign.right),
            ),
            const SizedBox(width: 16),
            SizedBox(width: 230, child: CategoryChip(v, rememberByDefault: true)),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: l.confirm,
              onPressed: canConfirm ? () => context.read<ExpenseRepository>().confirm(v.txn.id) : null,
              icon: const Icon(Icons.check),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: l.chooseCategory,
              onPressed: () => changeCategory(context, v, rememberByDefault: true),
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
      ),
    );
  }

  /// Statement text and location (`ACME CORP #12 MONTREAL QC`), ready to paste
  /// in a web search.
  Future<void> _copyForSearch(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final text = [v.txn.description, v.txn.location].whereType<String>().join(' ');
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(SnackBar(content: Text(l.copied(text)), duration: const Duration(seconds: 2)));
  }
}

/// Why the line is in the queue: where the suggested category came from
/// (stored `confidence`), with the word or reward rate behind it.
class _ReviewReason extends StatelessWidget {
  const _ReviewReason(this.v);

  final TxnView v;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final category = index.name(context, v.txn.categoryId);
    final rate = v.txn.bonusRate;
    // Nothing to explain on an uncategorized line: its "Uncategorized" chip says it.
    if (v.txn.categoryId == null && !const {'rule', 'merchant', 'bank', 'seed', 'keyword'}.contains(v.txn.confidence)) {
      return const SizedBox.shrink();
    }
    final (icon, text) = switch (v.txn.confidence) {
      'rule' => (Icons.rule, l.reasonRule),
      'merchant' => (Icons.history, l.reasonMerchant),
      'bank' => (Icons.account_balance, l.reasonBank(category)),
      'seed' => (Icons.storefront, l.reasonSeed),
      'keyword' => (Icons.search, l.reasonKeyword(matchedKeyword(v.txn.description)?.$1.trim() ?? '?')),
      'hint' when rate != null => (Icons.stars, l.reasonHint('${rate ~/ 100}', category)),
      _ => (Icons.help_outline, l.reasonNone),
    };
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: style?.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Other likely categories, learned from the reviewed lines: one click sets
/// the category of this line (only this one).
class _Suggestions extends StatelessWidget {
  const _Suggestions(this.v);

  final TxnView v;

  /// Guesses less likely than this are not worth a chip.
  static const _minProbability = 0.15;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final guesses = [
      for (final ClassifierGuess g in context.watch<CategoryClassifier>().suggest(v.txn.description, v.txn.location))
        if (g.probability >= _minProbability && g.categoryId != v.txn.categoryId && index[g.categoryId] != null) g,
    ];
    if (guesses.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final g in guesses)
            ActionChip(
              avatar: CircleAvatar(radius: 4, backgroundColor: groupColor(context, g.categoryId)),
              label: Text(index.name(context, g.categoryId)),
              tooltip: l.reasonLearned(g.support, g.word),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () => context.read<ExpenseRepository>().setCategory(v.txn.id, g.categoryId),
            ),
        ],
      ),
    );
  }
}
