// Locking and switching files (each with its own password) from the password
// screen, on real encrypted files.
import 'dart:io';

import 'package:expense_desktop/database_list.dart';
import 'package:expense_desktop/l10n/app_localizations.dart';
import 'package:expense_desktop/main.dart';
import 'package:expense_desktop/screens/shell.dart';
import 'package:expense_desktop/widgets/database_chooser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:storage/storage.dart';

const mine = 'correct horse battery staple';
const theirs = 'another long password 2026';

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1600, 1100);
    view.devicePixelRatio = 1;
  });
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('expenses-switch'));
  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // A background database isolate may still hold the file on Windows.
    }
  });

  Future<void> encrypted(File file, String password) async {
    Backups(file).prepare(password, ExpenseDatabase.currentSchemaVersion);
    final db = openEncryptedDatabase(file, password);
    await db.select(db.categories).get(); // the file is created on the first query
    await db.close();
  }

  /// Lets isolates (key derivation, database) work, then settles the frames.
  Future<void> wait(WidgetTester tester, [int seconds = 3]) async {
    await tester.runAsync(() => Future<void>.delayed(Duration(seconds: seconds)));
    await tester.pump();
    await tester.pump();
  }

  Future<void> unlock(WidgetTester tester, String password) async {
    await tester.enterText(find.byType(TextField), password);
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await Future<void>.delayed(const Duration(seconds: 3));
    });
    await wait(tester, 1);
  }

  /// The lock button, then "Lock" in its confirmation.
  Future<void> lock(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Lock (or switch file)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lock'));
    await wait(tester, 1);
  }

  testWidgets('lock, open another file with its password, lock, back to mine', (tester) async {
    final databases = DatabaseList.load(dir);
    final shared = File(p.join(dir.path, 'shared', 'partner.sqlite'));
    shared.parent.createSync();
    await tester.runAsync(() async {
      await encrypted(databases.home, mine);
      await encrypted(shared, theirs);
    });
    databases.use(shared);
    databases.use(databases.home);

    await tester.pumpWidget(UnlockGate(databases: databases, file: databases.last));
    expect(find.text('Your data'), findsOneWidget);
    await unlock(tester, mine);
    expect(find.byType(Shell), findsOneWidget);
    expect(find.text('partner'), findsNothing, reason: 'the app\'s own file is not named');

    await tester.tap(find.byTooltip('Lock (or switch file)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Shell), findsOneWidget, reason: 'cancel keeps the file open');

    await lock(tester);
    expect(find.byType(Shell), findsNothing);
    expect(find.text('Unlock your data'), findsOneWidget);

    await tester.tap(find.text('Change file'));
    await tester.pumpAndSettle();
    expect(find.byType(DatabaseChooserDialog), findsOneWidget);
    await tester.tap(find.text('partner'));
    await tester.pumpAndSettle();
    expect(find.text('partner'), findsOneWidget, reason: 'the screen names the chosen file');

    await unlock(tester, mine);
    expect(find.text('Wrong password.'), findsOneWidget, reason: 'each file has its own password');
    await unlock(tester, theirs);
    expect(find.byType(Shell), findsOneWidget);
    expect(find.widgetWithText(Chip, 'partner'), findsOneWidget, reason: 'another file is named in the top bar');
    expect(DatabaseList.load(dir).last.path, shared.path, reason: 'offered first at the next start');

    await lock(tester);
    await tester.tap(find.text('Change file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your data'));
    await tester.pumpAndSettle();
    await unlock(tester, mine);
    expect(find.byType(Shell), findsOneWidget);
    expect(find.byType(Chip), findsNothing);

    await tester.pumpWidget(const SizedBox()); // closes the app before the files go
    await wait(tester, 1);
    await tester.pump(const Duration(seconds: 1)); // drift's last stream timers
  });

  testWidgets('another file becomes my data: copied into the app folder, mine kept as a copy', (tester) async {
    final databases = DatabaseList.load(dir);
    final usb = File(p.join(dir.path, 'usb', 'expenses.sqlite'));
    usb.parent.createSync();
    await tester.runAsync(() async {
      await encrypted(databases.home, mine);
      await encrypted(usb, theirs);
    });
    databases.use(usb);
    databases.use(databases.home);

    await tester.pumpWidget(UnlockGate(databases: databases, file: databases.last));
    await tester.tap(find.text('Change file'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Use as my data'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your current data is kept as a copy'), findsOneWidget);
    await tester.tap(find.text('Use this file'));
    await tester.pumpAndSettle();

    expect(find.text('Your data'), findsOneWidget, reason: 'the password screen is on the app\'s own file');
    await unlock(tester, mine);
    expect(find.text('Wrong password.'), findsOneWidget, reason: 'it now has the copied file\'s password');
    await unlock(tester, theirs);
    expect(find.byType(Shell), findsOneWidget);
    expect(find.byType(Chip), findsNothing, reason: 'the app\'s own file');
    expect(usb.existsSync(), isTrue, reason: 'copied, never moved');
    expect(Backups(databases.home).list().where((b) => b.reason == 'before-replace'), hasLength(1));

    await tester.pumpWidget(const SizedBox());
    await wait(tester, 1);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a plaintext or missing file is refused in the chooser', (tester) async {
    late AppLocalizations l;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            l = AppLocalizations.of(c);
            return const SizedBox();
          },
        ),
      ),
    );
    final plain = File(p.join(dir.path, 'old.sqlite'));
    plain.writeAsBytesSync([...'SQLite format 3'.codeUnits, 0, ...List.filled(100, 0)]); // a header is enough
    expect(chooserProblem(l, plain), contains("isn't encrypted"));
    expect(chooserProblem(l, File(p.join(dir.path, 'none.sqlite'))), l.databaseNotFound);
    final ok = File(p.join(dir.path, 'ok.sqlite'));
    await tester.runAsync(() => encrypted(ok, mine));
    expect(chooserProblem(l, ok), isNull);
  });
}
