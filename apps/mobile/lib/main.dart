import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'lock.dart';
import 'phone_store.dart';
import 'screens/home.dart';
import 'screens/pair.dart';
import 'screens/unlock.dart';
import 'session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  runApp(MobileApp(session: Session(PhoneStore(dir))));
}

/// The app shell: localization, theme and the start flow.
class MobileApp extends StatelessWidget {
  const MobileApp({super.key, required this.session, this.scan, this.check});

  final Session session;

  /// Replaces the camera (tests).
  final Future<String?> Function(BuildContext context)? scan;

  /// Replaces the desktop lookup of the Home banner (tests).
  final Future<Offer?> Function()? check;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: session,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: StartFlow(session: session, scan: scan, check: check),
      ),
    );
  }
}

/// Pair, download, unlock, then Home; locks again after 5 minutes in the background.
class StartFlow extends StatefulWidget {
  const StartFlow({super.key, required this.session, this.scan, this.check});

  final Session session;
  final Future<String?> Function(BuildContext context)? scan;
  final Future<Offer?> Function()? check;

  @override
  State<StartFlow> createState() => _StartFlowState();
}

class _StartFlowState extends State<StartFlow> {
  late final AppLock _lock = AppLock(onLock: () => widget.session.lock());

  PhoneStore get _store => widget.session.store;

  @override
  void initState() {
    super.initState();
    _lock.attach();
  }

  @override
  void dispose() {
    _lock.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        if (widget.session.unlocked) {
          return HomePage(session: widget.session, check: widget.check ?? _store.available);
        }
        if (_store.openable != null) return UnlockScreen(session: widget.session);
        if (_store.readPairing() == null) {
          return PairScreen(scan: widget.scan, onPaired: (p) => setState(() => _store.savePairing(p)));
        }
        return DownloadScreen(store: _store, onDone: () => setState(() {}), onRepair: () => setState(_store.clear));
      },
    );
  }
}
