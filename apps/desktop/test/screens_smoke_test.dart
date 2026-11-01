// Opens every page and every Statistics tab of the real app on a database
// filled with the synthetic fixtures (a made-up household), and fails on any exception, layout
// overflow or error widget. Catches crashes like a widget breaking the
// dashboard (grey screen in release builds).
import 'dart:io';

import 'package:banks/banks.dart';
import 'package:banks/testing.dart' show loadFixture;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:expense_desktop/app_state.dart';
import 'package:expense_desktop/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

const fixtures = '../../packages/banks/test/fixtures';

Future<ExpenseDatabase> demoDatabase() async {
  final db = ExpenseDatabase(NativeDatabase.memory());
  final importer = ImportService(db);
  final files =
      Directory(fixtures)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains('.synthetic.'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    await importer.importStatement(readStatement(loadFixture(f.path)), fileHash: name, fileName: name);
  }
  await importer.refreshAutomaticCategories();
  return db;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Tests draw text with a placeholder font (every letter a wide square), which
  // overflows layouts that fit with real fonts: use Windows' UI font instead.
  setUpAll(() async {
    final font = File('${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/segoeui.ttf');
    if (!font.existsSync()) return;
    final loader = FontLoader('Roboto')..addFont(font.readAsBytes().then((b) => ByteData.view(b.buffer)));
    await loader.load();
  });

  for (final size in const [Size(1440, 900), Size(1280, 720)]) {
    testWidgets(
      'every page and statistics tab opens without error on demo data, ${size.width.round()}x${size.height.round()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final db = (await tester.runAsync(demoDatabase))!;
        addTearDown(() => tester.runAsync(db.close));

        // Database work runs on real time; widgets on fake time: alternate both.
        Future<void> settle() async {
          for (var i = 0; i < 8; i++) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        Future<void> open(String label) async {
          await tester.tap(find.text(label).first);
          await settle();
          expect(tester.takeException(), isNull, reason: label);
          expect(find.byType(ErrorWidget), findsNothing, reason: label);
        }

        await tester.pumpWidget(appFor(db));
        await settle();
        final startup = tester.takeException();
        expect(startup, isNull, reason: startup is FlutterError ? startup.toStringDeep() : '$startup');
        expect(find.text('Desjardins'), findsWidgets);

        for (final page in [
          'Dashboard',
          'Transactions',
          'Review',
          'Targets',
          'Import',
          'Accounts',
          'Categories & rules',
        ]) {
          await open(page);
        }

        // Import lists what the app reads; a missing bank leads to the masked-copy page.
        await open('Import');
        expect(find.text('Banks the app can read'), findsOneWidget);
        expect(find.textContaining('Desjardins · '), findsWidgets);
        await open("My bank or card isn't listed");
        expect(find.text('Add a bank'), findsOneWidget);
        await tester.pageBack();
        await settle();

        // Review: the copy button puts the statement text and location on the clipboard.
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
          return null;
        });
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );
        await open('Review');
        await tester.tap(find.byIcon(Icons.content_copy).first);
        await settle();
        expect(copied, isNotEmpty);
        expect(find.textContaining('Copied: $copied'), findsOneWidget);

        // Each line says why it is in review; the queue sorts by amount and merchant.
        expect(find.textContaining(RegExp('Bonidollars|No clue|Keyword|Bank hint|Known merchant')), findsWidgets);
        await open('Amount');
        await open('By merchant');

        // Bulk: select one line, pick a category with the keyboard, confirm the change.
        await tester.tap(find.byType(Checkbox).first);
        await settle();
        expect(find.text('1 selected'), findsOneWidget);
        await tester.tap(find.text('Choose a category').first);
        await settle();
        expect(find.text('Frequent'), findsOneWidget, reason: 'most used categories before any search');
        await tester.enterText(find.byType(TextField).last, 'gas');
        await settle();
        expect(find.textContaining('· gas'), findsOneWidget, reason: 'the word the category was found by');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settle();
        expect(find.textContaining('on 1 line?'), findsOneWidget, reason: 'nothing changes without confirming');
        await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
        await settle();
        expect(find.text('1 transaction updated'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await open('Statistics');
        for (final tab in ['Trends', 'Categories', 'Merchants', 'Compare', 'Balances', 'Recurring']) {
          await open(tab);
        }
        for (final range in ['6 months', 'This year', 'Last year', 'Everything']) {
          await open(range);
        }
        // Balances of the fixtures' accounts are drawn.
        await open('Balances');
        expect(find.text('Month-end balance'), findsOneWidget);

        // Categories: leaving a group out of shares adds the second share column, and back.
        await open('Categories');
        expect(find.text('Share excl.'), findsNothing);
        await tester.tap(find.byTooltip('Leave Housing out of shares (rent, taxes…)'));
        await settle();
        expect(find.text('Share excl.'), findsOneWidget);
        expect(find.textContaining('Shares without: Housing'), findsOneWidget);
        await tester.tap(find.text('Put all back'));
        await settle();
        expect(find.text('Share excl.'), findsNothing);
        expect(tester.takeException(), isNull);

        // Notifications: due statements and spending anomalies.
        await tester.tap(find.byTooltip('Notifications'));
        await settle();
        expect(tester.takeException(), isNull);
        expect(find.text('Notifications'), findsWidgets);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle();

        // A regular payment's alert opens Statistics on the Recurring tab.
        await open('Dashboard');
        tester.element(find.byType(Scaffold).first).read<AppState>().showRecurring(null);
        await settle();
        expect(find.text('Recurring per month'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // A regular payment's detail explains its alert; marking it normal (and back) by hand.
        await tester.tap(find.text('Virgin Plus').first);
        await settle();
        expect(find.textContaining('compared with the usual'), findsNWidgets(2));
        expect(find.text('Past unusual payment (no alert)'), findsOneWidget, reason: 'May, before the alert window');
        await tester.tap(find.text('This payment is normal').first);
        await settle();
        expect(find.textContaining('marked normal'), findsOneWidget);
        await tester.tap(find.text('Undo'));
        await settle();
        expect(find.text('This payment is normal'), findsNWidgets(2));
        await tester.tap(find.text('Close'));
        await settle();
        expect(tester.takeException(), isNull);

        // Leave the app so its streams and timers stop before the database closes.
        await tester.pumpWidget(const SizedBox());
        await settle();
      },
    );
  }
}
