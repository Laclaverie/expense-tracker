// Password screen (B11): choosing a long password typed twice, unlocking,
// changing it, restoring a copy made with an older one.
import 'dart:io';

import 'package:expense_desktop/l10n/app_localizations.dart';
import 'package:expense_desktop/screens/unlock.dart';
import 'package:expense_desktop/widgets/backup_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

const password = 'correct horse battery staple';
const other = 'another long password 2026';

Widget app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Finder button(String text) => find.widgetWithText(FilledButton, text);

bool enabled(WidgetTester tester, String text) => tester.widget<FilledButton>(button(text)).onPressed != null;

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1400, 1100);
    view.devicePixelRatio = 1;
  });
  late Directory dir;
  late File file;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('expenses-unlock');
    file = File('${dir.path}/expenses.sqlite');
  });
  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // A background database isolate may still hold the file on Windows.
    }
  });

  testWidgets('choosing a password: more than 16 characters, typed twice', (tester) async {
    final calls = <String>[];
    String? unlocked;
    await tester.pumpWidget(
      app(
        UnlockScreen(
          state: DatabaseFileState.missing,
          prepare: (p) async {
            calls.add(p);
            return UnlockOutcome.ok;
          },
          onUnlocked: (p, _) async => unlocked = p,
        ),
      ),
    );
    expect(find.text('Choose a password'), findsOneWidget);
    expect(find.textContaining('cannot be recovered'), findsOneWidget);
    expect(find.textContaining('existing data'), findsNothing, reason: 'nothing to convert');
    final fields = find.byType(TextField);
    expect(find.text('At least 17 characters. A sentence of a few words is the easiest to remember.'), findsOneWidget);

    await tester.enterText(fields.at(0), 'a');
    await tester.pump();
    expect(find.text('Too short: 1 character, at least 17 needed (16 more).'), findsOneWidget);
    await tester.enterText(fields.at(0), 'a' * 16);
    await tester.enterText(fields.at(1), 'a' * 16);
    await tester.pump();
    expect(find.text('Too short: 16 characters, at least 17 needed (1 more).'), findsOneWidget);
    final error = tester.widget<Text>(find.text('Too short: 16 characters, at least 17 needed (1 more).'));
    expect(error.style?.color, Theme.of(tester.element(fields.at(0))).colorScheme.error, reason: 'shown in red');
    expect(enabled(tester, 'Encrypt and open'), isFalse);

    await tester.enterText(fields.at(0), password);
    await tester.enterText(fields.at(1), '$password!');
    await tester.pump();
    expect(find.text('The two entries differ.'), findsOneWidget);
    expect(enabled(tester, 'Encrypt and open'), isFalse);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(calls, isEmpty, reason: 'Enter does nothing while the entries differ');

    await tester.enterText(fields.at(1), password);
    await tester.pump();
    expect(find.text('28 characters: long enough'), findsOneWidget);
    expect(enabled(tester, 'Encrypt and open'), isTrue);
    await tester.tap(button('Encrypt and open'));
    await tester.pump();
    await tester.pump();
    expect(calls, [password]);
    expect(unlocked, password);
  });

  testWidgets('the password is hidden until the eye is clicked', (tester) async {
    await tester.pumpWidget(
      app(
        UnlockScreen(
          state: DatabaseFileState.encrypted,
          prepare: (_) async => UnlockOutcome.ok,
          onUnlocked: (_, _) async {},
        ),
      ),
    );
    EditableText text() => tester.widget<EditableText>(find.byType(EditableText));
    expect(text().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show the password'));
    await tester.pump();
    expect(text().obscureText, isFalse);
  });

  testWidgets('a database from before encryption says what gets encrypted', (tester) async {
    await tester.pumpWidget(
      app(
        UnlockScreen(
          state: DatabaseFileState.plaintext,
          prepare: (_) async => UnlockOutcome.converted,
          onUnlocked: (_, _) async {},
        ),
      ),
    );
    expect(find.textContaining('existing data and the app\'s automatic copies are encrypted'), findsOneWidget);
    expect(find.textContaining('saved yourself elsewhere stay readable'), findsOneWidget);
  });

  testWidgets('unlocking: a wrong password is refused and cleared', (tester) async {
    String? unlocked;
    await tester.pumpWidget(
      app(
        UnlockScreen(
          state: DatabaseFileState.encrypted,
          prepare: (p) async => p == password ? UnlockOutcome.ok : UnlockOutcome.wrongPassword,
          onUnlocked: (p, _) async => unlocked = p,
        ),
      ),
    );
    expect(find.text('Unlock your data'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget, reason: 'typed once');
    await tester.enterText(find.byType(TextField), other);
    await tester.tap(button('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong password.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(unlocked, isNull);

    await tester.enterText(find.byType(TextField), password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump();
    expect(unlocked, password);
  });

  testWidgets('an unexpected failure is shown, and the password can be typed again', (tester) async {
    var fail = true;
    String? unlocked;
    await tester.pumpWidget(
      app(
        UnlockScreen(
          state: DatabaseFileState.encrypted,
          prepare: (_) async => fail ? throw const FileSystemException('file locked') : UnlockOutcome.ok,
          onUnlocked: (p, _) async => unlocked = p,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), password);
    await tester.tap(button('Unlock'));
    await tester.pump();
    expect(find.byWidgetPredicate((w) => w is SelectableText && w.data!.contains('file locked')), findsOneWidget);
    fail = false;
    await tester.tap(button('Unlock'));
    await tester.pump();
    await tester.pump();
    expect(unlocked, password);
  });

  testWidgets('prepareDatabase on real files: new, then wrong and right password', (tester) async {
    await tester.runAsync(() async {
      expect(await prepareDatabase(file.path, password), UnlockOutcome.ok);
      final db = openEncryptedDatabase(file, password);
      await db.select(db.categories).get(); // the file is created on the first query
      await db.close();
      expect(databaseFileState(file), DatabaseFileState.encrypted);
      expect(await prepareDatabase(file.path, other), UnlockOutcome.wrongPassword);
      expect(await prepareDatabase(file.path, password), UnlockOutcome.ok);
    });
  });

  testWidgets('changing the password checks the current one', (tester) async {
    late ExpenseDatabase db;
    final backups = Backups(file, password: password);
    await tester.runAsync(() async {
      backups.prepare(password, ExpenseDatabase.currentSchemaVersion);
      db = openEncryptedDatabase(file, password);
      await db.select(db.categories).get();
    });
    await tester.pumpWidget(
      Provider<ExpenseDatabase>.value(
        value: db,
        child: app(Scaffold(body: BackupDialog(backups: backups))),
      ),
    );
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    final fields = find.descendant(of: find.byType(ChangePasswordDialog), matching: find.byType(TextField));
    await tester.enterText(fields.at(0), other);
    await tester.enterText(fields.at(1), other);
    await tester.enterText(fields.at(2), other);
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(ChangePasswordDialog), matching: button('Change password')));
    await tester.pumpAndSettle();
    expect(find.text('Wrong password.'), findsOneWidget, reason: 'current password checked');

    await tester.enterText(fields.at(0), password);
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.descendant(of: find.byType(ChangePasswordDialog), matching: button('Change password')));
      await Future<void>.delayed(const Duration(seconds: 3));
    });
    await tester.pumpAndSettle();
    expect(find.text('Password changed.'), findsOneWidget);
    expect(backups.password, other);
    await tester.runAsync(() async {
      await db.close();
      expect(passwordOpens(file, other), isTrue);
      expect(passwordOpens(file, password), isFalse);
    });
  });

  testWidgets('restoring a copy made with an older password asks for it', (tester) async {
    late ExpenseDatabase db;
    final old = File('${dir.path}/old.sqlite');
    final backups = Backups(file, password: password);
    await tester.runAsync(() async {
      Backups(old).prepare(other, ExpenseDatabase.currentSchemaVersion);
      final oldDb = openEncryptedDatabase(old, other);
      await oldDb.select(oldDb.categories).get();
      await oldDb.close();
      backups.prepare(password, ExpenseDatabase.currentSchemaVersion);
      db = openEncryptedDatabase(file, password);
      await db.select(db.categories).get();
      // Listed among the automatic copies so the dialog can restore it.
      backups.folder.createSync(recursive: true);
      old.copySync('${backups.folder.path}/expenses-20261031-090000-before-import.sqlite');
    });
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(
      Provider<ExpenseDatabase>.value(
        value: db,
        child: app(Scaffold(body: BackupDialog(backups: backups))),
      ),
    );
    await tester.tap(find.text('Restore').first);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(button('Restore and restart'));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();
    expect(find.text('Password of this copy'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is SelectableText && w.data!.contains("doesn't open with that password")),
      findsOneWidget,
    );
    expect(backups.hasPendingRestore, isFalse);
  });
}
