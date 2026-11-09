import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sync/sync.dart';

import '../l10n/app_localizations.dart';
import '../phone_sync.dart';
import '../style.dart';

/// Pair the phone (QR code), send it the database, show when it last synced, forget it.
Future<void> showPhoneDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _PhoneDialog());

class _PhoneDialog extends StatefulWidget {
  const _PhoneDialog();

  @override
  State<_PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends State<_PhoneDialog> {
  late final PhoneSync _sync = context.read<PhoneSync?>()!;
  Timer? _tick;
  bool _showQr = false;
  PairingInfo? _info;
  bool _noNetwork = false;

  /// Pairing or showing the QR: the session is being prepared (copy, server). Buttons are disabled meanwhile.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onChange);
    _sync.refresh();
  }

  /// A one-second tick while serving, for the countdown and the hint.
  void _onChange() {
    if (_sync.serving && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!_sync.serving) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _sync.removeListener(_onChange);
    _tick?.cancel();
    super.dispose();
  }

  /// One pairing / QR at a time (a double click must not pair twice).
  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pair() => _guard(() async {
    await _sync.pair();
    await _serveAndShowQr();
  });

  Future<void> _revealQr() => _guard(_serveAndShowQr);

  /// Starts serving, then shows the QR code with the port the server bound: the phone downloads right after
  /// scanning, so the desktop must already be waiting for it (a re-scan of a paired phone too). Without a network
  /// there is no QR and no session; when the session can't start, its error shows instead of the QR.
  Future<void> _serveAndShowQr() async {
    setState(() {
      _showQr = true;
      _info = null;
      _noNetwork = false;
    });
    final hosts = (await _sync.pairingInfo())?.hosts ?? const <String>[];
    if (!mounted) return;
    if (hosts.isEmpty) {
      setState(() => _noNetwork = true);
      return;
    }
    await _sync.send();
    if (!mounted || !_sync.serving) return;
    final info = await _sync.pairingInfo();
    if (mounted) setState(() => _info = info);
  }

  Future<void> _forget() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.phoneForgetTitle),
        content: Text(l.phoneForgetBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.phoneForget)),
        ],
      ),
    );
    if (ok != true) return;
    await _sync.forget();
    if (mounted) setState(() => _showQr = false);
  }

  String _date(DateTime d) => DateFormat.yMMMd(lang(context)).add_Hm().format(d.toLocal());

  String _left(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Waiting for the phone (countdown, firewall hint), or why the session could not start.
  List<Widget> _serving(BuildContext context, PhoneSync sync) {
    final l = AppLocalizations.of(context);
    final error = TextStyle(color: Theme.of(context).colorScheme.error);
    if (!sync.serving) {
      return [
        if (sync.error != null) ...[const SizedBox(height: 16), Text(l.phoneFailed('${sync.error}'), style: error)],
      ];
    }
    return [
      const SizedBox(height: 16),
      const LinearProgressIndicator(),
      const SizedBox(height: 8),
      Text(l.phoneWaiting(_left(sync.remaining))),
      if (sync.showFirewallHint) ...[const SizedBox(height: 8), Text(l.phoneHint, style: error)],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sync = context.watch<PhoneSync?>()!;
    final phone = sync.phone;
    final children = <Widget>[];
    var actions = <Widget>[];

    if (!sync.loaded) {
      children.add(const Center(child: CircularProgressIndicator()));
    } else if (phone == null) {
      children.add(Text(l.phoneNotPaired));
      actions = [FilledButton(onPressed: _busy ? null : _pair, child: Text(l.phonePair))];
    } else if (_showQr) {
      children.addAll([
        if (_noNetwork)
          Text(l.phoneNoNetwork)
        else if (_info == null && _busy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(l.phonePreparing),
        ] else if (_info == null)
          // The session could not start: its error, no QR.
          ..._serving(context, sync)
        else ...[
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: QrImageView(data: _info!.encode(), size: 220, backgroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(l.phoneScan),
          ..._serving(context, sync),
        ],
      ]);
      actions = [
        TextButton(onPressed: _busy ? null : () => setState(() => _showQr = false), child: Text(l.phoneQrDone)),
      ];
    } else {
      children.add(Text(l.phonePairedOn(_date(phone.pairedAt))));
      children.add(Text(phone.lastSyncAt == null ? l.phoneLastSyncNever : l.phoneLastSync(_date(phone.lastSyncAt!))));
      if (sync.serving) {
        children.addAll(_serving(context, sync));
        actions = [TextButton(onPressed: sync.stop, child: Text(l.phoneStop))];
      } else {
        if (sync.syncedAt != null) {
          children.add(const SizedBox(height: 16));
          children.add(
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(l.phoneUpToDate(_date(sync.syncedAt!)))),
              ],
            ),
          );
        }
        if (sync.error != null) {
          children.add(const SizedBox(height: 16));
          children.add(
            Text(l.phoneFailed('${sync.error}'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          );
        }
        actions = [
          TextButton(onPressed: _forget, child: Text(l.phoneForget)),
          TextButton(onPressed: _busy ? null : _revealQr, child: Text(l.phoneShowQr)),
          FilledButton(onPressed: _busy ? null : sync.send, child: Text(l.phoneSend)),
        ];
      }
    }

    return AlertDialog(
      title: Text(l.phoneTitle),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
      actions: [
        ...actions,
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
      ],
    );
  }
}
