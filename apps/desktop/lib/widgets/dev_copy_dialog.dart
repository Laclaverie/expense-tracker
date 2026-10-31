import 'dart:io';
import 'dart:isolate';

import 'package:banks/banks.dart' show banks;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import 'password_fields.dart';

/// Result of [_write], sendable back from its isolate.
sealed class _Outcome {
  const _Outcome();
}

class _Written extends _Outcome {
  const _Written(this.report, this.path);
  final DevCopyReport report;
  final String path;
}

class _Leaked extends _Outcome {
  const _Leaked(this.words);
  final List<String> words;
}

class _Failed extends _Outcome {
  const _Failed(this.message);
  final String message;
}

/// The bank plug-ins' own wording: kept in the copy ([writeDevCopy]).
List<String> _bankWords() => [
  for (final b in banks)
    for (final r in b.lineRules) ...[?r.startsWith, ?r.contains],
];

/// A top-level function for [Isolate.run] (CLAUDE.md: never from a State method).
Future<_Outcome> _write(String source, String sourcePassword, String folder, String password, List<String> extra) {
  final keep = _bankWords();
  return Isolate.run(() {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final dir = Directory(
      '$folder${Platform.pathSeparator}expenses-dev-${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}',
    )..createSync(recursive: true);
    final target = File('${dir.path}${Platform.pathSeparator}expenses.sqlite');
    try {
      final report = writeDevCopy(
        source: File(source),
        sourcePassword: sourcePassword,
        target: target,
        password: password,
        keepWords: keep,
        extraSecrets: extra,
      );
      return _Written(report, target.path);
    } on DevCopyLeak catch (e) {
      if (dir.listSync().isEmpty) dir.deleteSync();
      return _Leaked(e.words);
    } on Object catch (e) {
      if (dir.existsSync() && dir.listSync().isEmpty) dir.deleteSync();
      return _Failed('$e');
    }
  });
}

/// Anonymized copy of the whole database for a developer: one-way, never a
/// backup. Its own password (not the owner's), extra words to hide, then a
/// summary of what was replaced.
class DevCopyDialog extends StatefulWidget {
  const DevCopyDialog({super.key, required this.backups});

  final Backups backups;

  @override
  State<DevCopyDialog> createState() => _DevCopyDialogState();
}

class _DevCopyDialogState extends State<DevCopyDialog> {
  final _extra = TextEditingController();
  String? _password;
  bool _busy = false;
  String? _error;
  _Outcome? _outcome;

  @override
  void dispose() {
    _extra.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l = AppLocalizations.of(context);
    final password = _password;
    if (password == null || _busy) return;
    if (password == widget.backups.password) {
      setState(() => _error = l.devCopySamePassword);
      return;
    }
    final folder = await getDirectoryPath();
    if (folder == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = await _write(
      widget.backups.databaseFile.path,
      widget.backups.password!,
      folder,
      password,
      _extra.text.split(RegExp(r'[\s,;]+')).where((w) => w.length >= 3).toList(),
    );
    if (mounted) {
      setState(() {
        _busy = false;
        _outcome = outcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final outcome = _outcome;
    return AlertDialog(
      title: Text(l.devCopyTitle),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: switch (outcome) {
              _Written(:final report, :final path) => [
                Text(l.devCopyDone, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SelectableText(path),
                const SizedBox(height: 12),
                Text(
                  l.devCopySummary(
                    report.merchantsReplaced,
                    report.people,
                    report.cities,
                    report.notes,
                    report.checkedCells,
                    report.checkedWords,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l.devCopyGive),
              ],
              _Leaked(:final words) => [
                Text(l.devCopyLeak, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 8),
                SelectableText(words.join(', ')),
              ],
              _Failed(:final message) => [SelectableText(l.backupFailed(message))],
              null => [
                Text(l.devCopyWhat),
                const SizedBox(height: 8),
                Text(l.devCopyNotBackup, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                NewPasswordFields(onChanged: (p) => setState(() => _password = p), onSubmitted: (_) => _create()),
                const SizedBox(height: 12),
                TextField(
                  controller: _extra,
                  decoration: InputDecoration(
                    labelText: l.devCopyExtra,
                    helperText: l.devCopyExtraHint,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (_busy) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l.devCopyWorking)),
                    ],
                  ),
                ],
              ],
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l.close)),
        if (outcome == null)
          FilledButton.icon(
            onPressed: _password == null || _busy ? null : _create,
            icon: const Icon(Icons.shield_outlined),
            label: Text(l.devCopyAction),
          ),
      ],
    );
  }
}
