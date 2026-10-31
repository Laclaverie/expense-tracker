import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:storage/storage.dart';

import '../database_list.dart';
import '../l10n/app_localizations.dart';

/// Name of [file] for people: "Vos données" for the app's own file.
String databaseLabel(AppLocalizations l, DatabaseList databases, File file) =>
    databases.isHome(file) ? l.databaseHome : p.basenameWithoutExtension(file.path);

/// On the password screen: which file it unlocks, and a button to pick another.
class DatabaseFileBar extends StatelessWidget {
  const DatabaseFileBar({super.key, required this.databases, required this.file, required this.onChosen});

  final DatabaseList databases;
  final File file;
  final ValueChanged<File> onChosen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        const Icon(Icons.description_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Tooltip(
            message: file.path,
            child: Text(databaseLabel(l, databases, file), style: t.titleSmall, overflow: TextOverflow.ellipsis),
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.swap_horiz),
          label: Text(l.databaseChange),
          onPressed: () async {
            final chosen = await showDialog<File>(
              context: context,
              builder: (_) => DatabaseChooserDialog(databases: databases, current: file),
            );
            if (chosen != null && !p.equals(chosen.path, file.path)) onChosen(chosen);
          },
        ),
      ],
    );
  }
}

/// The files opened before, and "Parcourir…" for another one. Returns the
/// chosen file. Only encrypted databases: a plaintext one would be
/// encrypted in place with a new password, so it goes through Restore.
class DatabaseChooserDialog extends StatefulWidget {
  const DatabaseChooserDialog({super.key, required this.databases, required this.current});

  final DatabaseList databases;
  final File current;

  @override
  State<DatabaseChooserDialog> createState() => _DatabaseChooserDialogState();
}

class _DatabaseChooserDialogState extends State<DatabaseChooserDialog> {
  String? _problem;

  /// "Parcourir…": a file not yet in the list.
  Future<void> _browse() async {
    final l = AppLocalizations.of(context);
    final picked = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'SQLite', extensions: ['sqlite']),
      ],
    );
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    final problem = chooserProblem(l, file);
    if (problem != null) {
      setState(() => _problem = problem);
    } else {
      Navigator.pop(context, file);
    }
  }

  /// [file] becomes the app's own database: copied into the app's folder
  /// (the one it replaces kept as a copy), then chosen. Nothing is open here.
  Future<void> _makeMain(File file) async {
    final l = AppLocalizations.of(context);
    final home = widget.databases.home;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.databaseMakeMainTitle(p.basenameWithoutExtension(file.path))),
        content: SizedBox(
          width: 480,
          child: Text(home.existsSync() ? l.databaseMakeMainReplace : l.databaseMakeMainNew),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.databaseMakeMainAction)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      Backups(home).adopt(file);
    } on Object catch (e) {
      setState(() => _problem = l.databaseMakeMainFailed('$e'));
      return;
    }
    widget.databases.use(home);
    if (mounted) Navigator.pop(context, home);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l.databaseChooseTitle),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.databaseChooseHint),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final file in widget.databases.files)
                    // A missing file stays listed (a USB key not plugged in), greyed.
                    ListTile(
                      dense: true,
                      selected: p.equals(file.path, widget.current.path),
                      enabled: file.existsSync() || widget.databases.isHome(file),
                      leading: Icon(widget.databases.isHome(file) ? Icons.home_outlined : Icons.description_outlined),
                      title: Text(databaseLabel(l, widget.databases, file)),
                      subtitle: Text(file.existsSync() ? file.path : l.databaseMissing(file.path)),
                      onTap: () => Navigator.pop(context, file),
                      trailing: widget.databases.isHome(file)
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (file.existsSync())
                                  IconButton(
                                    tooltip: l.databaseMakeMain,
                                    icon: const Icon(Icons.home_outlined),
                                    onPressed: () => _makeMain(file),
                                  ),
                                IconButton(
                                  tooltip: l.databaseForget,
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() => widget.databases.forget(file)),
                                ),
                              ],
                            ),
                    ),
                ],
              ),
            ),
            if (_problem != null) ...[
              const SizedBox(height: 12),
              SelectableText(_problem!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton.icon(onPressed: _browse, icon: const Icon(Icons.folder_open), label: Text(l.databaseBrowse)),
      ],
    );
  }
}

/// Why [file] can't be opened from the chooser, null when it can.
String? chooserProblem(AppLocalizations l, File file) => switch (databaseFileState(file)) {
  DatabaseFileState.missing => l.databaseNotFound,
  DatabaseFileState.plaintext => l.databasePlaintext,
  DatabaseFileState.encrypted => null,
};
