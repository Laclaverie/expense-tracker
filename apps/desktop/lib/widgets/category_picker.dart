import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import '../style.dart';

/// Result of [pickCategory].
class PickedCategory {
  const PickedCategory(this.categoryId, {this.remember = false});

  final String categoryId;

  /// Apply to the merchant's other transactions and future imports.
  final bool remember;
}

/// Shows the category tree (groups with their categories) and returns the
/// chosen leaf. When [merchantName] is given, offers to remember the choice.
Future<PickedCategory?> pickCategory(
  BuildContext context, {
  String? current,
  String? merchantName,
  bool rememberByDefault = true,
}) => showDialog<PickedCategory>(
  context: context,
  builder: (_) => _CategoryPicker(current: current, merchantName: merchantName, remember: rememberByDefault),
);

/// Picks what a target covers: all spending (returns `''`), a whole group, or
/// one category.
Future<String?> pickTargetCategory(BuildContext context, {String? current}) async {
  final picked = await showDialog<PickedCategory>(
    context: context,
    builder: (_) => _CategoryPicker(current: current, remember: false, forTargets: true),
  );
  return picked?.categoryId;
}

class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({this.current, this.merchantName, required this.remember, this.forTargets = false});

  final String? current;
  final String? merchantName;
  final bool remember;

  /// Groups and "all spending" are selectable too; income and excluded groups are hidden.
  final bool forTargets;

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  late bool _remember = widget.remember && widget.merchantName != null;
  String _filter = '';

  /// Keyboard highlight in [_results]; -1 = none (no search typed yet).
  int _cursor = -1;

  /// Most used categories, offered before any search.
  List<String> _frequent = const [];

  @override
  void initState() {
    super.initState();
    if (!widget.forTargets) {
      context.read<ExpenseRepository>().frequentCategories().then((f) {
        if (mounted) setState(() => _frequent = f);
      });
    }
  }

  /// Categories in display order: the frequent ones before a search, the
  /// matching ones while searching. Up / Down move through them, Enter picks.
  List<String> _results(CategoryIndex index, String filter) {
    if (filter.isEmpty) {
      return [
        for (final id in _frequent)
          if (index[id] != null && !index[id]!.archived) id,
      ];
    }
    return [
      for (final group in _ordered(index.groups))
        if (_matches(context, index, group.id, filter) && !(widget.forTargets && group.type != 'expense'))
          for (final c in index.childrenOf(group.id))
            if (index.matches(c.id, filter) || index.matches(group.id, filter)) c.id,
    ];
  }

  void _pick(String id) => Navigator.pop(context, PickedCategory(id, remember: _remember));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final filter = _filter.trim();
    final results = _results(index, filter);
    final cursor = results.isEmpty ? -1 : (filter.isEmpty ? _cursor : _cursor.clamp(0, results.length - 1));
    final highlighted = cursor < 0 ? null : results[cursor];
    void move(int by) {
      if (results.isNotEmpty) setState(() => _cursor = (cursor + by).clamp(0, results.length - 1));
    }

    BorderSide? side(String id) =>
        id == highlighted ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : null;
    return AlertDialog(
      title: Text(l.chooseCategory),
      content: SizedBox(
        width: 640,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.arrowDown): () => move(1),
                      const SingleActivator(LogicalKeyboardKey.arrowUp): () => move(-1),
                    },
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.categorySearchHint),
                      onChanged: (v) => setState(() {
                        _filter = v;
                        _cursor = -1;
                      }),
                      onSubmitted: (_) {
                        if (highlighted != null) _pick(highlighted);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _create(context, null),
                  icon: const Icon(Icons.add),
                  label: Text(_filter.trim().isEmpty ? l.newCategory : l.createNamed(_filter.trim())),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (widget.forTargets && filter.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ChoiceChip(
                        label: Text(l.allSpending),
                        selected: widget.current == '',
                        onSelected: (_) => Navigator.pop(context, const PickedCategory('')),
                      ),
                    ),
                  if (filter.isEmpty && results.isNotEmpty) ...[
                    Text(l.frequentCategories, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final id in results)
                          ChoiceChip(
                            avatar: CircleAvatar(radius: 5, backgroundColor: groupColor(context, id)),
                            label: Text(index.name(context, id)),
                            selected: id == widget.current,
                            side: side(id),
                            onSelected: (_) => _pick(id),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                  ],
                  for (final group in _ordered(index.groups))
                    if (_matches(context, index, group.id, filter) && !(widget.forTargets && group.type != 'expense'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 5, backgroundColor: groupColor(context, group.id)),
                                const SizedBox(width: 8),
                                if (widget.forTargets)
                                  ChoiceChip(
                                    label: Text(index.name(context, group.id)),
                                    selected: group.id == widget.current,
                                    onSelected: (_) => Navigator.pop(context, PickedCategory(group.id)),
                                  )
                                else
                                  Text(index.name(context, group.id), style: Theme.of(context).textTheme.titleSmall),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final c in index.childrenOf(group.id))
                                  if (index.matches(c.id, filter) || index.matches(group.id, filter))
                                    ChoiceChip(
                                      label: _label(context, index, c.id, filter),
                                      selected: c.id == widget.current,
                                      side: side(c.id),
                                      onSelected: (_) => _pick(c.id),
                                    ),
                                ActionChip(
                                  avatar: const Icon(Icons.add, size: 16),
                                  label: const Text(''),
                                  labelPadding: EdgeInsets.zero,
                                  tooltip: l.addToGroup(index.name(context, group.id)),
                                  onPressed: () => _create(context, group.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            if (widget.merchantName != null)
              CheckboxListTile(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
                title: Text(l.rememberMerchant(widget.merchantName!)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel))],
    );
  }

  /// Creates a category (name prefilled from the search) and selects it.
  Future<void> _create(BuildContext context, String? groupId) async {
    final l = AppLocalizations.of(context);
    final index = context.read<CategoryIndex>();
    final repo = context.read<ExpenseRepository>();
    final groups = [
      for (final g in index.groups)
        if (!widget.forTargets || g.type == 'expense') g,
    ];
    final suggested = widget.current == null || widget.current!.isEmpty ? null : widget.current!.split('.').first;
    var group = groupId ?? (groups.any((g) => g.id == suggested) ? suggested! : groups.first.id);
    final fr = TextEditingController(text: _filter.trim()), en = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setDialog) => AlertDialog(
          title: Text(l.newCategory),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: group,
                  decoration: InputDecoration(labelText: l.group),
                  items: [
                    for (final g in groups) DropdownMenuItem(value: g.id, child: Text(index.name(context, g.id))),
                  ],
                  onChanged: (v) => setDialog(() => group = v ?? group),
                ),
                TextField(
                  controller: fr,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l.nameFr),
                ),
                TextField(
                  controller: en,
                  decoration: InputDecoration(labelText: l.nameEn),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
            FilledButton(
              onPressed: () async {
                if (fr.text.trim().isEmpty) return;
                final navigator = Navigator.of(d);
                final id = await repo.addCategory(parentId: group, nameFr: fr.text, nameEn: en.text);
                navigator.pop(id);
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
    if (created != null && context.mounted) Navigator.pop(context, PickedCategory(created, remember: _remember));
  }

  /// The suggested group (when the suggestion is only a group) comes first.
  List<CategoryRow> _ordered(List<CategoryRow> groups) {
    final current = widget.current;
    if (current == null || current.contains('.')) return groups;
    return [...groups.where((g) => g.id == current), ...groups.where((g) => g.id != current)];
  }

  bool _matches(BuildContext context, CategoryIndex index, String groupId, String filter) =>
      index.matches(groupId, filter) || index.childrenOf(groupId).any((c) => index.matches(c.id, filter));

  /// While searching, why a category matched: the word it was found by
  /// ("Essence · gas") or its name in the other language ("Cadeaux · Gifts").
  Widget _label(BuildContext context, CategoryIndex index, String id, String filter) {
    final name = index.name(context, id);
    final alias = filter.isEmpty ? null : index.matchedAlias(id, filter)?.toLowerCase();
    final other = alias ?? index.otherName(context, id);
    if (filter.isEmpty || other.isEmpty || other.toLowerCase() == name.toLowerCase()) return Text(name);
    return Text.rich(
      TextSpan(
        text: name,
        children: [
          TextSpan(
            text: ' · $other',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
