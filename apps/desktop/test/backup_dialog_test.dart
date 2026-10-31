// Backup dialog: automatic copies listed with their reason, restore asks first.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:expense_desktop/l10n/app_localizations.dart';
import 'package:expense_desktop/widgets/backup_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

void main() {
  testWidgets('lists copies by reason; restore needs a confirmation', (tester) async {
    final dir = Directory.systemTemp.createTempSync('expenses-backup-dialog');
    final file = File('${dir.path}/expenses.sqlite');
    final db = ExpenseDatabase(NativeDatabase(file));
    var now = DateTime(2026, 10, 25, 9);
    final backups = Backups(file, clock: () => now);
    await tester.runAsync(() async {
      await backups.snapshot(db, 'before-import');
      now = now.add(const Duration(hours: 1));
      await backups.snapshot(db, 'before-v8');
    });
    addTearDown(() async {
      await tester.runAsync(db.close);
      dir.deleteSync(recursive: true);
    });

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
    expect(find.text('before an app update'), findsOneWidget);
    expect(find.text('before an import'), findsOneWidget);
    expect(find.textContaining('the last 15 are kept'), findsOneWidget);

    await tester.tap(find.text('Restore').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Go back to the data of'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(backups.hasPendingRestore, isFalse, reason: 'nothing staged without confirming');
    expect(tester.takeException(), isNull);
  });
}
