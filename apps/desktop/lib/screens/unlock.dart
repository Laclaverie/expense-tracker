import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import '../widgets/password_fields.dart';

/// Result of [prepareDatabase], sendable back from its isolate.
enum UnlockOutcome { ok, wrongPassword, converted }

/// Checks [password] on the database at [path] and prepares it
/// ([Backups.prepare]: encrypts a plaintext database and copies, copies
/// before a migration). Key derivation is slow on purpose: runs in an
/// isolate (a top-level function, see CLAUDE.md on `Isolate.run`).
Future<UnlockOutcome> prepareDatabase(String path, String password) => Isolate.run(() {
  try {
    final result = Backups(File(path)).prepare(password, ExpenseDatabase.currentSchemaVersion);
    return result.converted ? UnlockOutcome.converted : UnlockOutcome.ok;
  } on WrongPasswordException {
    return UnlockOutcome.wrongPassword;
  }
});

/// First screen: choose a password (new or plaintext database) or type it.
/// The app opens only once [onUnlocked] has the database ready.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key, required this.state, required this.onUnlocked, required this.prepare, this.header});

  /// Decides the screen: [DatabaseFileState.encrypted] asks for the password,
  /// the others ask to choose one.
  final DatabaseFileState state;

  /// The password, once [prepare] accepted it.
  final Future<void> Function(String password, UnlockOutcome outcome) onUnlocked;

  /// [prepareDatabase] on the database file (tests pass a fake).
  final Future<UnlockOutcome> Function(String password) prepare;

  /// Which file this unlocks, with a button to choose another.
  final Widget? header;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _password = TextEditingController();
  String? _chosen;
  bool _busy = false;
  bool _wrong = false;

  /// An unexpected failure (file locked, disk full…), shown as is.
  String? _error;

  bool get _setup => widget.state != DatabaseFileState.encrypted;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(String password) async {
    if (_busy || password.isEmpty) return;
    setState(() {
      _busy = true;
      _wrong = false;
      _error = null;
    });
    final UnlockOutcome outcome;
    try {
      outcome = await widget.prepare(password);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
      return;
    }
    if (!mounted) return;
    if (outcome == UnlockOutcome.wrongPassword) {
      setState(() {
        _busy = false;
        _wrong = true;
      });
      _password.clear();
      return;
    }
    await widget.onUnlocked(password, outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_outline, size: 40, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(_setup ? l.unlockSetupTitle : l.unlockTitle, style: t.headlineSmall),
                    const SizedBox(height: 12),
                    if (widget.header != null && !_busy) ...[
                      widget.header!,
                      const Divider(),
                      const SizedBox(height: 8),
                    ],
                    if (_setup) ...[
                      Text(l.unlockSetupWhy),
                      const SizedBox(height: 8),
                      _Warning(l.unlockSetupForget),
                      if (widget.state == DatabaseFileState.plaintext) ...[
                        const SizedBox(height: 8),
                        Text(l.unlockSetupExisting),
                      ],
                      const SizedBox(height: 16),
                      NewPasswordFields(onChanged: (p) => setState(() => _chosen = p), onSubmitted: _submit),
                    ] else
                      PasswordField(
                        controller: _password,
                        label: l.passwordLabel,
                        autofocus: true,
                        errorText: _wrong ? l.unlockWrong : null,
                        onSubmitted: _submit,
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      SelectableText(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    if (_busy)
                      Row(
                        children: [
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_setup ? l.unlockEncrypting : l.unlockOpening)),
                        ],
                      )
                    else
                      FilledButton.icon(
                        onPressed: _setup
                            ? (_chosen == null ? null : () => _submit(_chosen!))
                            : () => _submit(_password.text),
                        icon: const Icon(Icons.lock_open),
                        label: Text(_setup ? l.unlockSetupAction : l.unlockAction),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: scheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
