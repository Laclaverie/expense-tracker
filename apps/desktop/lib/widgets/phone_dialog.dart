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

  Future<void> _pair() async {
    await _sync.pair();
    await _revealQr();
  }

  Future<void> _revealQr() async {
    final info = await _sync.pairingInfo();
    if (!mounted) return;
    setState(() {
      _info = info;
      _noNetwork = info == null || info.hosts.isEmpty;
      _showQr = true;
    });
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
      actions = [FilledButton(onPressed: _pair, child: Text(l.phonePair))];
    } else if (_showQr) {
      children.addAll([
        if (_noNetwork)
          Text(l.phoneNoNetwork)
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
        ],
      ]);
      actions = [TextButton(onPressed: () => setState(() => _showQr = false), child: Text(l.phoneQrDone))];
    } else {
      children.add(Text(l.phonePairedOn(_date(phone.pairedAt))));
      children.add(Text(phone.lastSyncAt == null ? l.phoneLastSyncNever : l.phoneLastSync(_date(phone.lastSyncAt!))));
      if (sync.serving) {
        children.add(const SizedBox(height: 16));
        children.add(const LinearProgressIndicator());
        children.add(const SizedBox(height: 8));
        children.add(Text(l.phoneWaiting(_left(sync.remaining))));
        if (sync.showFirewallHint) {
          children.add(const SizedBox(height: 8));
          children.add(Text(l.phoneHint, style: TextStyle(color: Theme.of(context).colorScheme.error)));
        }
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
          TextButton(onPressed: _revealQr, child: Text(l.phoneShowQr)),
          FilledButton(onPressed: sync.send, child: Text(l.phoneSend)),
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
