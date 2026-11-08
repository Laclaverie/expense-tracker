import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sync/sync.dart';

import '../l10n/app_localizations.dart';
import '../phone_store.dart';
import '../sync_banner.dart';

/// Shows the camera full screen and returns the first QR text read, or null when the page is closed.
Future<String?> scanWithCamera(BuildContext context) =>
    Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const _CameraPage()));

class _CameraPage extends StatelessWidget {
  const _CameraPage();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.scanTitle)),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final text = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
              if (text != null && Navigator.of(context).canPop()) Navigator.of(context).pop(text);
            },
            errorBuilder: (context, error) => Center(child: Text(l.cameraDenied)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l.scanHint,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// First start: scan the desktop's QR code.
class PairScreen extends StatefulWidget {
  const PairScreen({super.key, required this.onPaired, this.scan});

  final void Function(PairingInfo pairing) onPaired;

  /// Returns the scanned text (tests pass a fake: the camera plugin has no Windows implementation).
  final Future<String?> Function(BuildContext context)? scan;

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  String? _error;

  Future<void> _scan() async {
    final text = await (widget.scan ?? scanWithCamera)(context);
    if (text == null || !mounted) return;
    try {
      widget.onPaired(PairingInfo.decode(text));
    } on FormatException {
      setState(() => _error = AppLocalizations.of(context).pairNotOurs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.pairTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.pairIntro),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _scan, icon: const Icon(Icons.qr_code_scanner), label: Text(l.pairScan)),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

/// First download after pairing, with progress.
class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key, required this.store, required this.onDone, required this.onRepair});

  final PhoneStore store;
  final VoidCallback onDone;

  /// Forget the pairing and go back to the scanner.
  final VoidCallback onRepair;

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  double? _fraction;
  String? _error;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_running) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _running = true;
      _error = null;
      _fraction = null;
    });
    try {
      await widget.store.update(
        progress: (received, total) {
          if (mounted) setState(() => _fraction = total == 0 ? null : received / total);
        },
      );
      if (mounted) widget.onDone();
    } on SyncException catch (e) {
      if (mounted) setState(() => _error = syncMessage(l, e));
    } on Object {
      if (mounted) setState(() => _error = l.errGeneric);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.downloadTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error == null) ...[
              LinearProgressIndicator(value: _fraction),
              const SizedBox(height: 12),
              if (_fraction != null) Text(l.downloadPercent((_fraction! * 100).round()), textAlign: TextAlign.center),
            ] else ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _running ? null : _run, child: Text(l.retry)),
              TextButton(onPressed: widget.onRepair, child: Text(l.unpair)),
            ],
          ],
        ),
      ),
    );
  }
}
