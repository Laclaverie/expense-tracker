import 'package:flutter/material.dart';
import 'package:sync/sync.dart';

import 'l10n/app_localizations.dart';
import 'phone_store.dart';
import 'session.dart';

/// The spec's message for each sync problem.
String syncMessage(AppLocalizations l, SyncException e) {
  switch (e.problem) {
    case SyncProblem.unreachable:
      return l.errUnreachable;
    case SyncProblem.notPaired:
      return l.errNotPaired;
    case SyncProblem.incomplete:
      return l.errIncomplete;
    case SyncProblem.schemaMismatch:
      final desktop = e.desktopSchema ?? 0;
      final app = e.appSchema ?? 0;
      return desktop > app ? l.errUpdatePhone : l.errUpdateDesktop;
  }
}

/// On Home: "New data from DATE - Download" when the desktop offers a different copy, the message of a
/// problem, and the "switch password" notice. Being offline is normal and shows nothing.
class SyncBanner extends StatefulWidget {
  const SyncBanner({super.key, required this.session, required this.check});

  final Session session;

  /// Asks the desktop for a newer copy ([PhoneStore.available]).
  final Future<Offer?> Function() check;

  @override
  State<SyncBanner> createState() => _SyncBannerState();
}

class _SyncBannerState extends State<SyncBanner> {
  Offer? _offer;
  String? _error;
  bool _busy = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _look();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _look() async {
    try {
      final offer = await widget.check();
      if (!_disposed) setState(() => _offer = offer);
    } on SyncException catch (e) {
      if (_disposed || e.problem == SyncProblem.unreachable) return;
      setState(() => _error = syncMessage(AppLocalizations.of(context), e));
    } on Object {
      if (!_disposed) setState(() => _error = AppLocalizations.of(context).errGeneric);
    }
  }

  Future<void> _download() async {
    final l = AppLocalizations.of(context);
    // The banner is replaced by the updating screen during the download: errors go to the app root.
    final messenger = ScaffoldMessenger.of(context);
    void fail(String message) =>
        _disposed ? messenger.showSnackBar(SnackBar(content: Text(message))) : setState(() => _error = message);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.sync();
      if (!_disposed) setState(() => _offer = null);
    } on SyncException catch (e) {
      fail(syncMessage(l, e));
    } on Object {
      fail(l.errGeneric);
    } finally {
      if (!_disposed) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = <Widget>[];
    if (widget.session.usingPrevious) {
      rows.add(_row(Icons.key_outlined, l.switchPasswordBanner, l.switchAction, () => widget.session.lock()));
    }
    if (_error != null) rows.add(_row(Icons.error_outline, _error!, null, null));
    if (_offer != null) {
      final date = _offer!.manifest.createdAt.toLocal();
      rows.add(
        _busy
            ? _row(Icons.sync, l.updating, null, null)
            : _row(Icons.cloud_download_outlined, l.newDataFrom(date), l.downloadAction, _download),
      );
    }
    return Column(children: rows);
  }

  Widget _row(IconData icon, String text, String? action, VoidCallback? onTap) => MaterialBanner(
    leading: Icon(icon),
    content: Text(text),
    actions: [if (action != null) TextButton(onPressed: onTap, child: Text(action)) else const SizedBox.shrink()],
  );
}
