import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import '../style.dart';
import '../widgets/backup_dialog.dart';
import '../widgets/category_picker.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final repo = context.read<ExpenseRepository>();
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Text(l.categories, style: t.headlineSmall),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _export(context),
                    icon: const Icon(Icons.upload_outlined),
                    label: Text(l.exportCategories),
                  ),
                  TextButton.icon(
                    onPressed: () => _import(context),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(l.importCategories),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => _addCategory(context, null),
                    icon: const Icon(Icons.add),
                    label: Text(l.addGroup),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(l.categoriesHint, style: t.bodySmall),
              const SizedBox(height: 12),
              for (final g in index.groups) ...[
                Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: groupColor(context, g.id)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _editCategory(context, g),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(index.name(context, g.id), style: t.titleSmall),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 22, top: 4, bottom: 14),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in index.childrenOf(g.id))
                        ActionChip(label: Text(index.name(context, c.id)), onPressed: () => _editCategory(context, c)),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: Text(l.addCategory),
                        onPressed: () => _addCategory(context, g.id),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Text(l.rules, style: t.headlineSmall),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: () => _addRule(context),
                    icon: const Icon(Icons.add),
                    label: Text(l.addRule),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<RuleRow>>(
                stream: repo.watchRules(),
                builder: (context, snap) {
                  final rules = snap.data ?? const <RuleRow>[];
                  if (rules.isEmpty) return Text(l.noRules, style: t.bodySmall);
                  return Column(
                    children: [
                      for (final r in rules)
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 5, backgroundColor: groupColor(context, r.categoryId)),
                          title: Text(
                            l.ruleSummary(
                              r.descriptionContains ?? r.merchantKey ?? r.code ?? '',
                              index.name(context, r.categoryId),
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: l.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => repo.deleteRule(r.id),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(l.rememberedMerchants, style: t.titleMedium),
              const SizedBox(height: 8),
              StreamBuilder<List<Merchant>>(
                stream: repo.watchRememberedMerchants(),
                builder: (context, snap) => Column(
                  children: [
                    for (final m in snap.data ?? const <Merchant>[])
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 5, backgroundColor: groupColor(context, m.categoryId)),
                        title: Text(l.merchantRule(m.name, index.name(context, m.categoryId))),
                        trailing: IconButton(
                          tooltip: l.delete,
                          icon: const Icon(Icons.close),
                          onPressed: () => repo.forgetMerchant(m.id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Saves categories (and optionally rules and business merchants) to a JSON file.
  Future<void> _export(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final db = context.read<ExpenseDatabase>();
    final messenger = ScaffoldMessenger.of(context);
    var rules = true, merchants = true;
    // What the file would hold, to show counts next to each choice.
    final preview = await CategoriesTransfer(db).export();
    final counts = (
      (preview['categories'] as List).length,
      (preview['rules'] as List).length,
      (preview['merchants'] as List).length,
    );
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          title: Text(l.exportTitle),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  value: true,
                  onChanged: null,
                  title: Text(l.exportCategoriesCount(counts.$1)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: merchants,
                  onChanged: (v) => set(() => merchants = v ?? false),
                  title: Text(l.exportMerchants(counts.$3)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: rules,
                  onChanged: (v) => set(() => rules = v ?? false),
                  title: Text(l.exportRules(counts.$2)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Text(l.exportPrivacy, style: Theme.of(d).textTheme.bodySmall),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.exportCategories)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final location = await getSaveLocation(
      suggestedName: 'categories-depenses.json',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (location == null) return;
    final data = await CategoriesTransfer(db).export(rules: rules, merchants: merchants);
    await File(location.path).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    messenger.showSnackBar(SnackBar(content: Text(l.exportDone(location.path))));
  }

  /// Adds categories, rules and merchants from an export file.
  Future<void> _import(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final db = context.read<ExpenseDatabase>();
    final messenger = ScaffoldMessenger.of(context);
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null || !context.mounted || !await backupBefore(context, 'before-categories')) return;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final r = await CategoriesTransfer(db).import(json);
      messenger.showSnackBar(
        SnackBar(content: Text(l.importDoneCategories(r.categories, r.rules, r.merchants, r.recategorized))),
      );
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l.importBadFile)));
    }
  }

  Future<void> _addCategory(BuildContext context, String? groupId) async {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final names = await _namesDialog(context, groupId == null ? l.addGroup : l.addCategory, '', '');
    if (names != null) await repo.addCategory(parentId: groupId, nameFr: names.$1, nameEn: names.$2);
  }

  Future<void> _editCategory(BuildContext context, CategoryRow c) async {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final result = await _namesDialog(context, l.editCategory, c.nameFr, c.nameEn, canArchive: true);
    if (result == null || !context.mounted) return;
    if (result.$3) {
      await _archive(context, c);
    } else {
      await repo.renameCategory(c.id, nameFr: result.$1, nameEn: result.$2.isEmpty ? result.$1 : result.$2);
    }
  }

  Future<void> _archive(BuildContext context, CategoryRow c) async {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final index = context.read<CategoryIndex>();
    final usage = await repo.categoryUsage(c.id);
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Text([l.archiveConfirm(index.name(context, c.id)), if (usage > 0) l.archiveMove(usage)].join('\n\n')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(usage > 0 ? l.chooseCategory : l.archive)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    String? moveTo;
    if (usage > 0) {
      final picked = await pickCategory(context);
      if (picked == null || picked.categoryId == c.id || picked.categoryId.startsWith('${c.id}.')) return;
      moveTo = picked.categoryId;
    }
    await repo.archiveCategory(c.id, moveTo: moveTo);
  }

  /// Returns (French name, English name, archive requested).
  Future<(String, String, bool)?> _namesDialog(
    BuildContext context,
    String title,
    String fr,
    String en, {
    bool canArchive = false,
  }) {
    final l = AppLocalizations.of(context);
    final frText = TextEditingController(text: fr), enText = TextEditingController(text: en);
    return showDialog<(String, String, bool)>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frText,
                autofocus: true,
                decoration: InputDecoration(labelText: l.nameFr),
              ),
              TextField(
                controller: enText,
                decoration: InputDecoration(labelText: l.nameEn),
              ),
            ],
          ),
        ),
        actions: [
          if (canArchive)
            TextButton.icon(
              onPressed: () => Navigator.pop(d, (frText.text, enText.text, true)),
              icon: const Icon(Icons.archive_outlined),
              label: Text(l.archive),
            ),
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              if (frText.text.trim().isNotEmpty) Navigator.pop(d, (frText.text.trim(), enText.text.trim(), false));
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  Future<void> _addRule(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final text = TextEditingController();
    final contains = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.addRule),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: text,
            autofocus: true,
            decoration: InputDecoration(labelText: l.ruleContains),
            onSubmitted: (v) => Navigator.pop(c, v),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, text.text), child: Text(l.chooseCategory)),
        ],
      ),
    );
    if (contains == null || contains.trim().isEmpty || !context.mounted) return;
    final picked = await pickCategory(context);
    if (picked == null) return;
    await repo.addRule(categoryId: picked.categoryId, descriptionContains: contains.trim());
  }
}
