// Developer copy dialog: says it is not a backup, needs its own long password.
import 'dart:io';

import 'package:expense_desktop/l10n/app_localizations.dart';
import 'package:expense_desktop/widgets/backup_dialog.dart';
import 'package:expense_desktop/widgets/dev_copy_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

const owner = 'correct horse battery staple';

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1400, 1100);
    view.devicePixelRatio = 1;
  });

  testWidgets('opened from the backups; not a backup; refuses the owner\'s own password', (tester) async {
    final dir = Directory.systemTemp.createTempSync('expenses-devcopy-dialog');
    final backups = Backups(File('${dir.path}/expenses.sqlite'), password: owner);
    late ExpenseDatabase db;
    await tester.runAsync(() async {
      backups.prepare(owner, ExpenseDatabase.currentSchemaVersion);
      db = openEncryptedDatabase(backups.databaseFile, owner);
      await db.select(db.categories).get();
    });
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(
      Provider<ExpenseDatabase>.value(
        value: db,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BackupDialog(backups: backups)),
        ),
      ),
    );
    await tester.tap(find.text('Anonymized copy for a developer'));
    await tester.pumpAndSettle();
    expect(find.byType(DevCopyDialog), findsOneWidget);
    expect(find.textContaining('This is not a backup'), findsOneWidget);
    expect(find.textContaining('MARCHAND 001'), findsOneWidget);

    Finder create() => find.widgetWithText(FilledButton, 'Choose a folder and create');
    bool enabled() => tester.widget<FilledButton>(create()).onPressed != null;
    expect(enabled(), isFalse);
    final fields = find.descendant(of: find.byType(DevCopyDialog), matching: find.byType(TextField));
    await tester.enterText(fields.at(0), owner);
    await tester.enterText(fields.at(1), owner);
    await tester.pump();
    expect(enabled(), isTrue);
    await tester.tap(create());
    await tester.pump();
    expect(find.textContaining('Choose another password than yours'), findsOneWidget);
  });
}
