// Phone dialog: pairing shows a QR, a transfer to a (loopback) phone records the sync, forgetting asks first.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:expense_desktop/l10n/app_localizations.dart';
import 'package:expense_desktop/phone_sync.dart';
import 'package:expense_desktop/widgets/phone_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:storage/storage.dart';
import 'package:sync/sync.dart';

void main() {
  late Directory dir;
  late ExpenseDatabase db;
  late PhoneSync sync;

  // The test binding answers every HttpClient with 400: the phone side needs real sockets.
  setUp(() => HttpOverrides.global = null);

  Future<void> start(WidgetTester tester, {List<String> hosts = const ['192.168.1.20']}) async {
    dir = Directory.systemTemp.createTempSync('expenses-phone');
    db = ExpenseDatabase(NativeDatabase(File('${dir.path}/expenses.sqlite')));
    sync = PhoneSync(
      db,
      Directory('${dir.path}/sync'),
      bindAddress: InternetAddress.loopbackIPv4,
      discoveryPort: 0,
      hosts: () async => hosts,
    );
    addTearDown(() async {
      await tester.runAsync(() async {
        await sync.stop();
        await db.close();
      });
      sync.dispose();
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Still held for a moment on Windows.
      }
    });
    await tester.pumpWidget(
      ListenableProvider<PhoneSync?>.value(
        value: sync,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (c) => Scaffold(
              body: TextButton(onPressed: () => showPhoneDialog(c), child: const Text('open')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  Future<void> pairAndSend(WidgetTester tester) async {
    await tester.tap(find.text('Pair a phone'));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('Send to phone'), findsOneWidget);
    // Started on real time: the server's callbacks must not wait for the fake clock's microtasks.
    await tester.runAsync(sync.send);
    await settle(tester);
    expect(sync.error, isNull);
  }

  testWidgets('not paired shows the pair button, pairing shows a QR', (tester) async {
    await start(tester);
    expect(find.text('Pair a phone'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);

    await tester.tap(find.text('Pair a phone'));
    await settle(tester);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Scan with the Dépenses app on your phone'), findsOneWidget);
    final info = PairingInfo.decode((await tester.runAsync(sync.pairingInfo))!.encode());
    expect(info.hosts, ['192.168.1.20']);
    expect(info.port, defaultPort);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a network the QR is replaced by a message', (tester) async {
    await start(tester, hosts: const []);
    await tester.tap(find.text('Pair a phone'));
    await settle(tester);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('No network found'), findsOneWidget);
  });

  testWidgets('send then a client download records the sync', (tester) async {
    await start(tester);
    await pairAndSend(tester);
    expect(find.textContaining('Waiting for the phone'), findsOneWidget);
    expect(sync.contacted, isFalse);

    final row = (await tester.runAsync(sync.store.current))!;
    final pairing = PairingInfo(databaseId: row.databaseId, hosts: ['127.0.0.1'], port: sync.port!, secret: row.secret);
    final target = File('${dir.path}/phone.sqlite');
    await tester.runAsync(() async {
      final client = SyncClient(pairing);
      final m = await client.manifest('127.0.0.1', sync.port!);
      expect(m.schemaVersion, ExpenseDatabase.currentSchemaVersion);
      await client.download('127.0.0.1', sync.port!, m, target);
      await client.ack('127.0.0.1', sync.port!, m.sha256);
      while (sync.serving) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await settle(tester);

    expect(find.textContaining('Phone up to date'), findsOneWidget);
    expect(find.textContaining('Last sync: never'), findsNothing);
    expect(target.existsSync(), isTrue);
    expect(File('${dir.path}/sync/phone-copy.sqlite').existsSync(), isFalse, reason: 'the copy is deleted');
    final after = (await tester.runAsync(sync.store.current))!;
    expect(after.lastSyncAt, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stop ends the session and deletes the copy', (tester) async {
    await start(tester);
    await pairAndSend(tester);
    await tester.tap(find.text('Stop'));
    await settle(tester);
    expect(sync.serving, isFalse);
    expect(find.text('Send to phone'), findsOneWidget);
    expect(File('${dir.path}/sync/phone-copy.sqlite').existsSync(), isFalse);
  });

  testWidgets('forget asks for confirmation then removes the pairing', (tester) async {
    await start(tester);
    await tester.tap(find.text('Pair a phone'));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.textContaining('Phone paired on'), findsOneWidget);

    await tester.tap(find.text('Forget phone'));
    await settle(tester);
    expect(find.text('Forget this phone?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(await tester.runAsync(sync.store.current), isNotNull, reason: 'cancel keeps the pairing');

    await tester.tap(find.text('Forget phone'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Forget phone'));
    await settle(tester);
    expect(await tester.runAsync(sync.store.current), isNull);
    expect(find.text('Pair a phone'), findsOneWidget);
  });
}

/// Database and socket work runs on real time, widgets on fake time: alternate both.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
