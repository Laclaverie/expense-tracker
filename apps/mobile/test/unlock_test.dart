import 'dart:io';

import 'package:core/core.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:expense_mobile/l10n/app_localizations.dart';
import 'package:expense_mobile/main.dart';
import 'package:expense_mobile/phone_store.dart';
import 'package:expense_mobile/screens/pair.dart';
import 'package:expense_mobile/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';
import 'package:sync/sync.dart';

import 'helpers.dart';

void main() {
  late Directory root;
  late PhoneStore store;
  final originalClock = appClock;
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> makeDatabase(File file, String password) async {
    final db = openEncryptedDatabase(file, password);
    await db.customSelect('select 1').get();
    await db.close();
  }

  Session newSession() => Session(
    store,
    check: (path, password) async => passwordOpens(File(path), password),
    open: (file, password) => ExpenseDatabase(NativeDatabase.memory(), readOnly: true),
  );

  Future<void> start(WidgetTester tester, Session session) async {
    await tester.pumpWidget(MobileApp(session: session, check: () async => null));
    await tester.pump();
  }

  Future<void> typeAndUnlock(WidgetTester tester, String password) async {
    await tester.enterText(find.byType(TextField), password);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('unlock_test_');
    store = PhoneStore(root);
  });

  tearDown(() {
    appClock = originalClock;
    try {
      root.deleteSync(recursive: true);
    } on FileSystemException {
      // Best effort.
    }
  });

  testWidgets('wrong password shows an error, right one opens Home', (tester) async {
    await tester.runAsync(() => makeDatabase(store.database, 'right-pass'));
    store.previous.writeAsBytesSync([1, 2, 3]);
    final session = newSession();
    await start(tester, session);

    await typeAndUnlock(tester, 'nope');
    expect(find.text('Wrong password'), findsOneWidget);
    expect(session.unlocked, isFalse);

    await typeAndUnlock(tester, 'right-pass');
    expect(find.text('Home'), findsOneWidget);
    expect(session.unlocked, isTrue);
    expect(store.previous.existsSync(), isFalse, reason: 'opening the new file drops the old copy');
    await closeApp(tester);
  });

  testWidgets('Forget this desktop in Settings asks, then deletes everything and shows pairing', (tester) async {
    await tester.runAsync(() => makeDatabase(store.database, 'right-pass'));
    store.savePairing(
      PairingInfo(databaseId: 'db-1', hosts: ['192.0.2.10'], port: 47820, secret: List<int>.filled(32, 7)),
    );
    final session = newSession();
    await start(tester, session);
    await typeAndUnlock(tester, 'right-pass');
    await tester.tap(find.text('Settings').last);
    await settle(tester);

    await tester.tap(find.text('Forget this desktop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(session.unlocked, isTrue, reason: 'cancel keeps everything');

    await tester.tap(find.text('Forget this desktop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forget'));
    await settle(tester);
    expect(session.unlocked, isFalse);
    expect(store.readPairing(), isNull);
    expect(store.database.existsSync(), isFalse);
    expect(find.byType(PairScreen), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('locks after 5 minutes in background', (tester) async {
    await tester.runAsync(() => makeDatabase(store.database, 'right-pass'));
    final session = newSession();
    var now = DateTime(2026, 11, 8, 12);
    appClock = () => now;
    await start(tester, session);
    await typeAndUnlock(tester, 'right-pass');
    expect(find.text('Home'), findsOneWidget);

    // Four minutes: still open.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 4));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Home'), findsOneWidget);

    // Five minutes: back to the password screen, the database closed.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 5));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text('Home'), findsNothing);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(session.unlocked, isFalse);
  });

  testWidgets('new data under another password: previous opens with a switch banner', (tester) async {
    await tester.runAsync(() async {
      await makeDatabase(store.database, 'new-pass');
      await makeDatabase(store.previous, 'old-pass');
    });
    final session = newSession();
    await start(tester, session);

    await typeAndUnlock(tester, 'old-pass');
    expect(find.text('Home'), findsOneWidget);
    expect(find.textContaining('another password'), findsOneWidget);
    expect(store.previous.existsSync(), isTrue);

    await tester.tap(find.text('Switch'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Enter your password'), findsOneWidget);
    await typeAndUnlock(tester, 'new-pass');
    expect(find.text('Home'), findsOneWidget);
    expect(find.textContaining('another password'), findsNothing);
    expect(store.previous.existsSync(), isFalse);
    await closeApp(tester);
  });

  testWidgets('a QR code that is not ours is refused, ours is paired', (tester) async {
    final pairing = PairingInfo(databaseId: 'db-1', hosts: ['192.168.1.5'], port: 47820, secret: List.filled(32, 7));
    PairingInfo? paired;
    var text = 'https://example.com';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PairScreen(onPaired: (p) => paired = p, scan: (_) async => text),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();
    expect(find.text('This QR code is not from Dépenses'), findsOneWidget);
    expect(paired, isNull);

    text = pairing.encode();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();
    expect(paired?.databaseId, 'db-1');
  });
}
