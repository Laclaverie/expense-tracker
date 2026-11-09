import 'package:flutter/material.dart';
import 'package:sync/sync.dart';

import '../l10n/app_localizations.dart';
import '../phone_store.dart';
import '../session.dart';
import '../sync_banner.dart';

/// The paired desktop, the age of the data, "check for new data", the language and Lock.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.session});

  final Session session;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  Session get _session => widget.session;

  Future<void> _check() async {
    final l = AppLocalizations.of(context);
    // The app root outlives the screens, which are rebuilt when the new data opens.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    String message;
    try {
      final result = await _session.sync();
      message = result == UpdateResult.updated ? l.dataUpdated : l.upToDate;
    } on SyncException catch (e) {
      message = syncMessage(l, e);
    } on Object {
      message = l.errGeneric;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pairing = _session.store.readPairing();
    final date = _session.store.dataDate();
    final language = _session.locale?.languageCode;
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.computer_outlined),
          title: Text(l.pairedDesktop),
          subtitle: Text(
            pairing == null || pairing.hosts.isEmpty ? l.notPaired : '${pairing.hosts.first}:${pairing.port}',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: Text(date == null ? l.dataDateUnknown : l.dataFrom(date.toLocal())),
        ),
        ListTile(
          leading: _busy
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sync),
          title: Text(l.checkNewData),
          enabled: !_busy,
          onTap: _check,
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l.languageLabel),
          trailing: DropdownButton<String?>(
            value: language,
            onChanged: _session.setLanguage,
            items: [
              DropdownMenuItem(value: null, child: Text(l.languageDevice)),
              DropdownMenuItem(value: 'fr', child: Text(l.languageFr)),
              DropdownMenuItem(value: 'en', child: Text(l.languageEn)),
            ],
          ),
        ),
        const Divider(),
        ListTile(leading: const Icon(Icons.lock_outline), title: Text(l.lockNow), onTap: _session.lock),
        if (pairing != null)
          ListTile(leading: const Icon(Icons.link_off), title: Text(l.forgetDesktop), enabled: !_busy, onTap: _forget),
      ],
    );
  }

  Future<void> _forget() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.forgetDesktop),
        content: Text(l.forgetDesktopConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.forgetAction)),
        ],
      ),
    );
    if (ok == true) await _session.forget();
  }
}
