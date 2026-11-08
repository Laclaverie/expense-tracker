import 'dart:io';

import 'package:core/core.dart' show CategoryClassifier;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import 'app_state.dart';
import 'database_list.dart';
import 'db_location.dart';
import 'l10n/app_localizations.dart';
import 'phone_sync.dart';
import 'screens/shell.dart';
import 'screens/unlock.dart';
import 'style.dart';
import 'widgets/database_chooser.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The app's own file: %APPDATA%\dev.lasagna\expense-tracker\expenses.sqlite (see db_location.dart),
  // encrypted with the owner's password (storage/encryption.dart); other files can be opened from the
  // password screen. Before anything: apply a restore chosen before the restart (a file copy, no password).
  final databases = DatabaseList.load(await databaseDirectory());
  final password = scratchPassword();
  final file = password != null ? databases.home : databases.last;
  await Backups(file).applyPendingRestore();
  runApp(UnlockGate(databases: databases, file: file, password: password));
}

/// The password screen, then the app on the unlocked database; locking
/// closes it and shows the password screen again, for this file or another.
class UnlockGate extends StatefulWidget {
  const UnlockGate({super.key, required this.databases, required this.file, this.password});

  final DatabaseList databases;

  /// Offered first.
  final File file;

  /// Given for a scratch database (`EXPENSES_DB_PASSWORD`): no screen the first time.
  final String? password;

  @override
  State<UnlockGate> createState() => _UnlockGateState();
}

class _UnlockGateState extends State<UnlockGate> {
  late File _file = widget.file;
  ExpenseDatabase? _db;
  PhoneSync? _phone;
  Widget? _app;
  String? _error;

  /// The scratch password is used for the first opening only.
  late bool _scratch = widget.password != null;

  @override
  void initState() {
    super.initState();
    final password = widget.password;
    if (password != null) {
      prepareDatabase(_file.path, password).then((outcome) {
        if (outcome == UnlockOutcome.wrongPassword) {
          setState(() => _error = 'EXPENSES_DB_PASSWORD does not open ${_file.path}');
        } else {
          _open(password, outcome);
        }
      });
    }
  }

  @override
  void dispose() {
    _phone?.dispose();
    super.dispose();
  }

  /// Called once [prepareDatabase] accepted [password].
  Future<void> _open(String password, UnlockOutcome outcome) async {
    final file = _file;
    final db = openEncryptedDatabase(file, password);
    // New default categories and merchant rules also apply to past imports.
    // Done before the first screen so no view starts from a half-updated state.
    await ImportService(db).refreshAutomaticCategories();
    if (!mounted) {
      await db.close();
      return;
    }
    widget.databases.use(file);
    final session = DatabaseSession(file: file, isHome: widget.databases.isHome(file), lock: _lock);
    setState(() {
      _db = db;
      _scratch = false;
      _phone = PhoneSync(db, Directory('${file.parent.path}${Platform.pathSeparator}sync'));
      _app = appFor(
        db,
        backups: Backups(file, password: password),
        session: session,
        phoneSync: _phone,
      );
    });
  }

  /// Back to the password screen; the database closes once the app is gone.
  void _lock() {
    final db = _db;
    _phone?.dispose();
    _phone = null;
    setState(() {
      _app = null;
      _db = null;
    });
    if (db != null) WidgetsBinding.instance.addPostFrameCallback((_) => db.close());
  }

  /// Another file chosen on the password screen.
  Future<void> _switch(File file) async {
    await Backups(file).applyPendingRestore();
    if (mounted) setState(() => _file = file);
  }

  @override
  Widget build(BuildContext context) {
    if (_app != null) return _app!;
    return MaterialApp(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: _scratch
          ? Scaffold(body: Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!)))
          : UnlockScreen(
              // A new screen (empty field, right state) for each file.
              key: ValueKey(_file.path),
              state: databaseFileState(_file),
              prepare: (p) => prepareDatabase(_file.path, p),
              onUnlocked: _open,
              header: DatabaseFileBar(databases: widget.databases, file: _file, onChosen: _switch),
            ),
    );
  }
}

ThemeData appTheme(Brightness b) => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A78D6), brightness: b),
  visualDensity: VisualDensity.compact,
);

/// The whole app on [db] (tests pass an in-memory database and no [backups]:
/// no copies made, no backup button; no [session]: no lock button; no [phoneSync]: no phone button).
Widget appFor(ExpenseDatabase db, {Backups? backups, DatabaseSession? session, PhoneSync? phoneSync}) => MultiProvider(
  providers: [
    Provider.value(value: db),
    Provider<Backups?>.value(value: backups),
    Provider<DatabaseSession?>.value(value: session),
    // Null in tests: no phone button.
    ListenableProvider<PhoneSync?>.value(value: phoneSync),
    Provider(create: (_) => ExpenseRepository(db)),
    Provider(create: (_) => ImportService(db)),
    ChangeNotifierProvider(create: (_) => AppState()),
    StreamProvider<CategoryIndex>(
      create: (c) => c.read<ExpenseRepository>().watchCategories().map(CategoryIndex.new),
      initialData: CategoryIndex(const []),
    ),
    // Learned from reviewed lines, retrained when they change: one-click suggestions in review.
    StreamProvider<CategoryClassifier>(create: (_) => watchClassifier(db), initialData: CategoryClassifier()),
  ],
  child: const ExpenseApp(),
);

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      locale: context.watch<AppState>().locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Shell(),
    );
  }
}
