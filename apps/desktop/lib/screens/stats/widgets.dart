// Small widgets shared by the Statistics tabs (sortable column title, notice, line lists).

import 'package:flutter/material.dart';
import 'package:storage/storage.dart';

import '../../widgets/transactions_dialog.dart';
import 'data.dart';

/// Column title that sorts its list: a tap picks the column, a second tap
/// reverses the order. The active column shows an arrow.
class SortHeader extends StatelessWidget {
  const SortHeader(
    this.text, {
    super.key,
    required this.active,
    required this.descending,
    required this.onTap,
    this.width,
    this.align = TextAlign.right,
  });

  final String text;
  final bool active;
  final bool descending;
  final VoidCallback onTap;

  /// Null: takes the remaining width.
  final double? width;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    final child = InkWell(
      onTap: onTap,
      child: Text(
        text + (active ? (descending ? ' ↓' : ' ↑') : ''),
        style: active ? style?.copyWith(fontWeight: FontWeight.w700) : style,
        textAlign: align,
      ),
    );
    return width == null ? Expanded(child: child) : SizedBox(width: width, child: child);
  }
}

void showCategoryLines(BuildContext context, StatsData d, {required String categoryId, required String title}) =>
    showSpendingDialog(
      context,
      title: title,
      filter: TxnFilter(scope: d.scope, from: d.from, to: d.to, categoryId: categoryId.isEmpty ? null : categoryId),
      uncategorizedOnly: categoryId.isEmpty,
    );

/// Info card above the tabs (same look as the coverage notice).
class StatsNotice extends StatelessWidget {
  const StatsNotice(this.icon, this.text, {super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
