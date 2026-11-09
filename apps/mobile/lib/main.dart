import 'dart:io';

import 'package:flutter/material.dart';
import 'package:storage/storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'lock.dart';
import 'phone_store.dart';
import 'screens/pair.dart';
import 'screens/unlock.dart';
import 'session.dart';
import 'shell.dart';
import 'state.dart';
import 'style.dart';

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
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) => phoneMaterialApp(
          locale: session.locale,
          home: StartFlow(session: session, scan: scan, check: check),
        ),
      ),
    );
  }
}

/// The MaterialApp every screen lives in: localization and theme.
MaterialApp phoneMaterialApp({Locale? locale, required Widget home}) => MaterialApp(
  onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
  theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
  darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark, useMaterial3: true),
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// Providers for the screens of one open database: the repository (reads only) and the category names.
class MobileProviders extends StatelessWidget {
  const MobileProviders({super.key, required this.db, required this.state, required this.child});

  final ExpenseDatabase db;
  final PhoneState state;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: db),
      Provider(create: (_) => ExpenseRepository(db)),
      ChangeNotifierProvider.value(value: state),
      StreamProvider<CategoryIndex>(
        create: (c) => c.read<ExpenseRepository>().watchCategories().map(CategoryIndex.new),
        initialData: CategoryIndex(const []),
      ),
    ],
    child: child,
  );
}

/// The app on an already open database, for tests (the real app opens it through [StartFlow]).
Widget mobileAppFor(ExpenseDatabase db, {PhoneStore? store, Session? session, Future<Offer?> Function()? check}) =>
    _Standalone(db: db, store: store, session: session, check: check);

class _Standalone extends StatefulWidget {
  const _Standalone({required this.db, this.store, this.session, this.check});

  final ExpenseDatabase db;
  final PhoneStore? store;
  final Session? session;
  final Future<Offer?> Function()? check;

  @override
  State<_Standalone> createState() => _StandaloneState();
}

class _StandaloneState extends State<_Standalone> {
  final _state = PhoneState();
  late final Session _session =
      widget.session ?? Session(widget.store ?? PhoneStore(Directory.systemTemp.createTempSync('phone_')));

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _session,
    child: ListenableBuilder(
      listenable: _session,
      builder: (context, _) => phoneMaterialApp(
        locale: _session.locale,
        home: MobileProviders(
          db: widget.db,
          state: _state,
          child: Shell(session: _session, check: widget.check ?? () async => null),
        ),
      ),
    ),
  );
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
  final PhoneState _state = PhoneState();
  late bool _wasUnlocked = widget.session.unlocked;

  PhoneStore get _store => widget.session.store;

  @override
  void initState() {
    super.initState();
    _lock.attach();
    widget.session.addListener(_onSession);
  }

  /// A lock closes every page above the root: no page with data stays visible behind the password screen.
  void _onSession() {
    final unlocked = widget.session.unlocked;
    if (_wasUnlocked && !unlocked) Navigator.of(context).popUntil((route) => route.isFirst);
    _wasUnlocked = unlocked;
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    _state.dispose();
    _lock.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        // The file is being replaced: no password screen (typing it now would open the old file).
        if (widget.session.syncing) return const UpdatingScreen();
        if (widget.session.unlocked) {
          return MobileProviders(
            key: ObjectKey(widget.session.db),
            db: widget.session.db!,
            state: _state,
            child: Shell(session: widget.session, check: widget.check ?? _store.available),
          );
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

/// Shown while newer data replaces the file.
class UpdatingScreen extends StatelessWidget {
  const UpdatingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).updating),
        ],
      ),
    ),
  );
}
