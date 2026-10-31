import 'package:flutter/material.dart';
import 'package:storage/storage.dart' show PasswordProblem, minPasswordLength, passwordProblem;

import '../l10n/app_localizations.dart';

/// One password field: hidden by default, an eye to show it while typing.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.errorText,
    this.helperText,
    this.helper,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final String? errorText;
  final String? helperText;

  /// Shown under the field instead of [helperText] (an icon with its text).
  final Widget? helper;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        helperText: widget.helper == null ? widget.helperText : null,
        helper: widget.helper,
        helperMaxLines: 2,
        errorMaxLines: 2,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _visible ? l.passwordHide : l.passwordShow,
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}

/// A new password typed twice, more than 16 characters ([passwordProblem]).
/// [onChanged] gets the password once valid, null otherwise.
class NewPasswordFields extends StatefulWidget {
  const NewPasswordFields({super.key, required this.onChanged, this.onSubmitted, this.autofocus = true});

  final ValueChanged<String?> onChanged;

  /// Enter in the second field with a valid password.
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<NewPasswordFields> createState() => _NewPasswordFieldsState();
}

class _NewPasswordFieldsState extends State<NewPasswordFields> {
  final _first = TextEditingController();
  final _second = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    widget.onChanged(passwordProblem(_first.text, _second.text) == null ? _first.text : null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final length = _first.text.runes.length;
    final problem = passwordProblem(_first.text, _second.text);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PasswordField(
          controller: _first,
          label: l.passwordNew,
          autofocus: widget.autofocus,
          // The rule before typing; what is missing, in red, while too short.
          helperText: length == 0 ? l.passwordRule(minPasswordLength) : null,
          helper: length >= minPasswordLength
              ? Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(l.passwordLengthOk(length), style: Theme.of(context).textTheme.bodySmall),
                  ],
                )
              : null,
          errorText: length > 0 && length < minPasswordLength
              ? l.passwordTooShort(length, minPasswordLength, minPasswordLength - length)
              : null,
          onChanged: (_) => _changed(),
        ),
        const SizedBox(height: 12),
        PasswordField(
          controller: _second,
          label: l.passwordConfirm,
          errorText: _second.text.isNotEmpty && problem == PasswordProblem.mismatch ? l.passwordMismatch : null,
          onChanged: (_) => _changed(),
          onSubmitted: (_) {
            if (problem == null) widget.onSubmitted?.call(_first.text);
          },
        ),
      ],
    );
  }
}
