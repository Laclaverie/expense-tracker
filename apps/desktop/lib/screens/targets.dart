import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../style.dart';
import '../targets_view.dart';
import '../widgets/category_picker.dart';
import '../widgets/keyed_stream.dart';

/// Spending targets of the selected scope, for the periods containing the
/// selected month's reference day (today in the current month).
class TargetsScreen extends StatelessWidget {
  const TargetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    // Targets are per institution, whatever account is selected.
    final scope = state.scope?.whole;
    if (scope == null) return Center(child: Text(l.noData));
    final repo = context.read<ExpenseRepository>();
    final reference = state.referenceDay;
    final (from, to) = linesWindow(reference);
    return KeyedStreamBuilder<List<TargetRow>>(
      streamKey: scope,
      stream: () => repo.watchTargets(scope),
      builder: (context, targets) => KeyedStreamBuilder<List<(DateTime, String?, int)>>(
        streamKey: (scope, from),
        stream: () => repo.watchSpendingLines(scope, from, to),
        builder: (context, lines) {
          final views = computeTargets(targets ?? const [], lines ?? const [], reference, DateTime.now());
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Text(l.navTargets, style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => showTargetDialog(context, scope, lines ?? const [], reference),
                    icon: const Icon(Icons.add),
                    label: Text(l.addTarget),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(l.targetsHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              if (views.isEmpty) Text(l.noTargets),
              for (final v in views) _TargetCard(v, scope, lines ?? const [], reference),
            ],
          );
        },
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard(this.v, this.scope, this.lines, this.reference);

  final TargetView v;
  final Scope scope;
  final List<(DateTime, String?, int)> lines;
  final DateTime reference;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final t = Theme.of(context).textTheme;
    final currency = scopeCurrency(scope);
    final p = v.progress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 6, backgroundColor: groupColor(context, v.row.categoryId)),
                const SizedBox(width: 8),
                Text(targetName(context, index, v.row.categoryId), style: t.titleMedium),
                const SizedBox(width: 12),
                Chip(label: Text(periodLabel(l, v.period)), visualDensity: VisualDensity.compact),
                const SizedBox(width: 8),
                Text(periodName(context, v.period, v.start, v.end), style: t.bodySmall),
                const Spacer(),
                StatusChip(p.status),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showTargetDialog(context, scope, lines, reference, existing: v.row),
                ),
                IconButton(
                  tooltip: l.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => context.read<ExpenseRepository>().deleteTarget(v.row.id),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TargetBar(p),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  l.targetSpent(money(context, p.spent, currency), money(context, p.target, currency)),
                  style: t.bodyLarge,
                ),
                const SizedBox(width: 16),
                Text(l.targetProjected(money(context, p.projected, currency)), style: t.bodyMedium),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${l.history} :', style: t.bodySmall),
                for (final (s, e, spent) in v.history.reversed)
                  Tooltip(
                    message:
                        '${money(context, spent, currency)} / ${money(context, v.row.amount, currency)} — '
                        '${spent <= v.row.amount ? l.withinTarget : l.status_over}',
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(
                        spent <= v.row.amount ? Icons.check : Icons.close,
                        size: 16,
                        color: statusColor(spent <= v.row.amount ? TargetStatus.onTrack : TargetStatus.over),
                      ),
                      label: Text(periodName(context, v.period, s, e), style: t.bodySmall),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Creates or edits a target. Suggests the average of the last 3 periods.
Future<void> showTargetDialog(
  BuildContext context,
  Scope scope,
  List<(DateTime, String?, int)> lines,
  DateTime reference, {
  TargetRow? existing,
}) => showDialog(context: context, builder: (_) => _TargetDialog(scope, lines, reference, existing));

class _TargetDialog extends StatefulWidget {
  const _TargetDialog(this.scope, this.lines, this.reference, this.existing);

  final Scope scope;
  final List<(DateTime, String?, int)> lines;
  final DateTime reference;
  final TargetRow? existing;

  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  late String? _category = widget.existing?.categoryId;
  late TargetPeriod _period = widget.existing == null
      ? TargetPeriod.month
      : TargetPeriod.values.byName(widget.existing!.period);
  late final _amount = TextEditingController(
    text: widget.existing == null ? '' : (widget.existing!.amount / 100).toStringAsFixed(0),
  );

  int? get _cents {
    final v = double.tryParse(_amount.text.replaceAll(',', '.').replaceAll(' ', ''));
    return v == null || v <= 0 ? null : (v * 100).round();
  }

  int get _suggestion => suggestTarget([
    for (final (s, e) in previousPeriods(_period, widget.reference, 3)) spentIn(widget.lines, _category, s, e),
  ]);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final currency = scopeCurrency(widget.scope);
    final suggestion = _suggestion;
    return AlertDialog(
      title: Text(widget.existing == null ? l.addTarget : l.editTarget),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              icon: CircleAvatar(radius: 5, backgroundColor: groupColor(context, _category)),
              label: Text(targetName(context, index, _category)),
              onPressed: widget.existing != null
                  ? null
                  : () async {
                      final picked = await pickTargetCategory(context, current: _category ?? '');
                      if (picked != null) setState(() => _category = picked.isEmpty ? null : picked);
                    },
            ),
            const SizedBox(height: 12),
            SegmentedButton<TargetPeriod>(
              segments: [for (final p in TargetPeriod.values) ButtonSegment(value: p, label: Text(periodLabel(l, p)))],
              selected: {_period},
              onSelectionChanged: widget.existing != null ? null : (s) => setState(() => _period = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(labelText: l.amount, suffixText: currency == 'EUR' ? '€' : '\$'),
              onChanged: (_) => setState(() {}),
            ),
            if (suggestion > 0) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _amount.text = (suggestion / 100).toStringAsFixed(0)),
                child: Text(l.targetSuggestion(money(context, suggestion, currency))),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: _cents == null
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  await context.read<ExpenseRepository>().saveTarget(widget.scope, _category, _period, _cents!);
                  navigator.pop();
                },
          child: Text(l.save),
        ),
      ],
    );
  }
}
