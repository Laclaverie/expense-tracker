import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import '../style.dart';
import 'category_picker.dart';
import 'split_editor.dart';

/// Shows a transaction's category; tap to change it (offering to remember it
/// for the merchant).
class CategoryChip extends StatelessWidget {
  const CategoryChip(this.view, {super.key, this.rememberByDefault = false});

  final TxnView view;
  final bool rememberByDefault;

  @override
  Widget build(BuildContext context) {
    final index = context.watch<CategoryIndex>();
    if (view.isSplit) {
      return ActionChip(
        avatar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in view.splits.take(3))
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: CircleAvatar(backgroundColor: groupColor(context, s.categoryId), radius: 4),
              ),
          ],
        ),
        label: Text(AppLocalizations.of(context).splitLabel(view.splits.length)),
        tooltip: view.splits.map((s) => index.name(context, s.categoryId)).join(' · '),
        onPressed: () => showSplitEditor(context, view),
      );
    }
    final id = view.txn.categoryId;
    final suggestedOnly = view.txn.needsReview;
    return ActionChip(
      avatar: CircleAvatar(backgroundColor: groupColor(context, id), radius: 5),
      label: Text(
        index.name(context, id),
        overflow: TextOverflow.ellipsis,
        style: suggestedOnly ? const TextStyle(fontStyle: FontStyle.italic) : null,
      ),
      onPressed: () => changeCategory(context, view, rememberByDefault: rememberByDefault),
    );
  }
}

Future<void> changeCategory(BuildContext context, TxnView view, {bool rememberByDefault = false}) async {
  final repo = context.read<ExpenseRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);
  final picked = await pickCategory(
    context,
    current: view.txn.categoryId,
    merchantName: view.merchant?.name,
    rememberByDefault: rememberByDefault,
  );
  if (picked == null) return;
  final count = await repo.setCategory(view.txn.id, picked.categoryId, rememberForMerchant: picked.remember);
  if (count > 1) messenger.showSnackBar(SnackBar(content: Text(l.updatedCount(count))));
}
