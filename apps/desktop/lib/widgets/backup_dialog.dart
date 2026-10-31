import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import '../style.dart';
import 'dev_copy_dialog.dart';
import 'password_fields.dart';

/// Copies the database before a change ([reason]: `before-import`…). Returns
/// false, after telling the user, when the copy failed: the caller then
/// changes nothing. Always true in tests (no [Backups]).
Future<bool> backupBefore(BuildContext context, String reason) async {
  final backups = context.read<Backups?>();
  if (backups == null) return true;
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await backups.snapshot(context.read<ExpenseDatabase>(), reason);
    return true;
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.backupFailed('$e'))));
    return false;
  }
}

/// Automatic copies, a manual copy to a chosen folder, restore.
class BackupDialog extends StatefulWidget {
  const BackupDialog({super.key, required this.backups});

  final Backups backups;

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> {
  String? _message;

  String _reason(AppLocalizations l, String reason) => switch (reason) {
    'before-import' => l.backupReasonImport,
    'before-restore' => l.backupReasonRestore,
    'before-categories' => l.backupReasonCategories,
    _ when reason.startsWith('before-v') => l.backupReasonUpdate,
    _ => reason,
  };

  String _date(DateTime d) => DateFormat.yMMMd(lang(context)).add_Hm().format(d);

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final db = context.read<ExpenseDatabase>();
    final folder = await getDirectoryPath();
    if (folder == null) return;
    try {
      final file = await widget.backups.saveTo(db, Directory(folder));
      setState(() => _message = l.backupSaved(file.path));
    } on Object catch (e) {
      setState(() => _message = l.backupFailed('$e'));
    }
  }

  Future<void> _restoreFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'SQLite', extensions: ['sqlite']),
      ],
    );
    if (file != null) await _restore(File(file.path), null);
  }

  /// Checks [file], asks, then restarts the app on it; the current data is copied first.
  Future<void> _restore(File file, DateTime? date) async {
    final l = AppLocalizations.of(context);
    final db = context.read<ExpenseDatabase>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l.backupRestoreConfirm(date == null ? file.uri.pathSegments.last : _date(date))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.backupRestoreAction)),
        ],
      ),
    );
    if (ok != true) return;
    String? filePassword;
    for (;;) {
      try {
        widget.backups.stageRestore(file, ExpenseDatabase.currentSchemaVersion, filePassword: filePassword);
        break;
      } on RestoreException catch (e) {
        // A copy made before the password changed: ask the password it was made with.
        if (e.problem == RestoreProblem.wrongPassword && mounted) {
          filePassword = await _askCopyPassword(retry: filePassword != null);
          if (filePassword != null) continue;
        }
        setState(
          () => _message = switch (e.problem) {
            RestoreProblem.notADatabase => l.restoreNotDatabase,
            RestoreProblem.newerVersion => l.restoreNewer,
            RestoreProblem.notExpenses => l.restoreNotExpenses,
            RestoreProblem.wrongPassword => l.restoreWrongPassword,
            RestoreProblem.devCopy => l.restoreDevCopy,
          },
        );
        return;
      }
    }
    // The open database can't be replaced: restart, main() applies the restore before opening it.
    await db.close();
    await Process.start(Platform.resolvedExecutable, const [], mode: ProcessStartMode.detached);
    exit(0);
  }

  /// The password a copy was made with; null when cancelled.
  Future<String?> _askCopyPassword({required bool retry}) => showDialog<String>(
    context: context,
    builder: (_) => _CopyPasswordDialog(retry: retry),
  );

  Future<void> _changePassword() async {
    final l = AppLocalizations.of(context);
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => ChangePasswordDialog(backups: widget.backups, db: context.read<ExpenseDatabase>()),
    );
    if (changed == true) setState(() => _message = l.passwordChanged);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final copies = widget.backups.list();
    return AlertDialog(
      // A short window: the whole content scrolls.
      scrollable: true,
      title: Text(l.backupTitle),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Where the open database is: AppData is hidden, and other files can be open.
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: SelectableText(l.backupDatabaseFile(widget.backups.databaseFile.path))),
                IconButton(
                  tooltip: l.backupShowFile,
                  icon: const Icon(Icons.folder_open),
                  onPressed: () => Process.run('explorer', ['/select,${widget.backups.databaseFile.path}']),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.backupHint(widget.backups.keep)),
            const SizedBox(height: 12),
            if (copies.isEmpty)
              Text(l.backupNone)
            else
              // At most [Backups.keep] copies: listed in full, the dialog scrolls.
              for (final b in copies)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.history),
                  title: Text(_date(b.date)),
                  subtitle: Text(_reason(l, b.reason)),
                  trailing: TextButton(onPressed: () => _restore(b.file, b.date), child: Text(l.backupRestore)),
                ),
            if (_message != null) ...[const SizedBox(height: 12), SelectableText(_message!)],
          ],
        ),
      ),
      actions: [
        if (widget.backups.password != null) ...[
          TextButton.icon(onPressed: _changePassword, icon: const Icon(Icons.password), label: Text(l.passwordChange)),
          TextButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => DevCopyDialog(backups: widget.backups),
            ),
            icon: const Icon(Icons.shield_outlined),
            label: Text(l.devCopyButton),
          ),
        ],
        TextButton.icon(
          onPressed: () => Process.run('explorer', [widget.backups.folder.path]),
          icon: const Icon(Icons.folder_open),
          label: Text(l.backupOpenFolder),
        ),
        TextButton.icon(onPressed: _restoreFile, icon: const Icon(Icons.restore), label: Text(l.backupRestoreFile)),
        FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_alt), label: Text(l.backupSave)),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
      ],
    );
  }
}

/// Current password, then the new one twice. Copies already made keep the
/// password they were made with (restoring one asks for it).
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.backups, required this.db});

  final Backups backups;
  final ExpenseDatabase db;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  String? _new;
  bool _wrong = false;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final next = _new;
    if (next == null || _busy) return;
    if (_current.text != widget.backups.password) {
      setState(() => _wrong = true);
      return;
    }
    setState(() => _busy = true);
    await widget.backups.changePassword(widget.db, next);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.passwordChange),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.passwordChangeHint),
            const SizedBox(height: 16),
            PasswordField(
              controller: _current,
              label: l.passwordCurrent,
              autofocus: true,
              errorText: _wrong ? l.unlockWrong : null,
              onChanged: (_) => setState(() => _wrong = false),
            ),
            const SizedBox(height: 16),
            NewPasswordFields(
              autofocus: false,
              onChanged: (p) => setState(() => _new = p),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(onPressed: _new == null || _busy ? null : _submit, child: Text(l.passwordChange)),
      ],
    );
  }
}

/// Asks the password an older copy was made with.
class _CopyPasswordDialog extends StatefulWidget {
  const _CopyPasswordDialog({required this.retry});

  /// The previous attempt was wrong.
  final bool retry;

  @override
  State<_CopyPasswordDialog> createState() => _CopyPasswordDialogState();
}

class _CopyPasswordDialogState extends State<_CopyPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.restorePasswordTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.restorePasswordHint),
            const SizedBox(height: 12),
            PasswordField(
              controller: _controller,
              label: l.passwordLabel,
              autofocus: true,
              errorText: widget.retry ? l.unlockWrong : null,
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text(l.backupRestoreAction)),
      ],
    );
  }
}
