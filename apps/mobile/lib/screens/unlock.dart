import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../session.dart';

/// Asks for the database password. It stays in memory ([Session]) and is never written anywhere.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key, required this.session});

  final Session session;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _wrong = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _password.text;
    if (_busy || text.isEmpty) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _wrong = false;
      _error = null;
    });
    try {
      final outcome = await widget.session.unlock(text);
      if (!mounted) return;
      if (outcome == UnlockOutcome.wrong) {
        _password.clear();
        setState(() => _wrong = true);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = l.unlockFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_outline, size: 40, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(l.unlockTitle, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofocus: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: l.passwordLabel,
                    errorText: _wrong ? l.unlockWrong : null,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                if (_busy)
                  Row(
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text(l.unlockOpening),
                    ],
                  )
                else
                  FilledButton(onPressed: _submit, child: Text(l.unlockButton)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
