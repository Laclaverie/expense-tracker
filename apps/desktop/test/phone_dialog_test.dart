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

  Future<void> start(
    WidgetTester tester, {
    List<String> hosts = const ['192.168.1.20'],
    InternetAddress? bindAddress,
  }) async {
    dir = Directory.systemTemp.createTempSync('expenses-phone');
    db = ExpenseDatabase(NativeDatabase(File('${dir.path}/expenses.sqlite')));
    sync = _CountingSync(
      db,
      Directory('${dir.path}/sync'),
      bindAddress: bindAddress ?? InternetAddress.loopbackIPv4,
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

  /// Pairs and waits (up to 5 s of real time) until the QR shows or the session failed.
  Future<void> pairAndWait(WidgetTester tester) async {
    await tester.tap(find.text('Pair a phone'));
    await pumpUntil(tester, () => find.byType(QrImageView).evaluate().isNotEmpty || sync.error != null);
  }

  /// Ends the session the QR started: its window timer runs on the fake clock.
  Future<void> doneAndStop(WidgetTester tester) async {
    await tester.tap(find.text('Done'));
    await settle(tester);
    await tester.tap(find.text('Stop'));
    await settle(tester);
  }

  /// Session copies left in the scratch folder.
  List<File> copies() {
    final scratch = Directory('${dir.path}/sync');
    if (!scratch.existsSync()) return const [];
    return scratch.listSync().whereType<File>().where((f) => f.uri.pathSegments.last.startsWith('phone-copy')).toList();
  }

  Future<void> pairAndSend(WidgetTester tester) async {
    await pairAndWait(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);
    // Pairing started a session; stop it to test the Send button's own.
    await tester.tap(find.text('Stop'));
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

    await pairAndWait(tester);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Scan with the Dépenses app on your phone'), findsOneWidget);
    // The phone downloads right after scanning: the desktop is already serving.
    expect(sync.serving, isTrue);
    expect(sync.error, isNull);
    expect(find.textContaining('Waiting for the phone'), findsOneWidget);
    final info = PairingInfo.decode((await tester.runAsync(sync.pairingInfo))!.encode());
    expect(info.hosts, ['192.168.1.20']);
    expect(info.port, sync.port);
    expect(tester.takeException(), isNull);
    await doneAndStop(tester);
  });

  testWidgets('the QR carries the port actually bound when the default one is busy', (tester) async {
    // Hold the default port (another program may hold it already: the server moves on either way).
    final blocker = await tester.runAsync(() async {
      try {
        return await ServerSocket.bind(InternetAddress.loopbackIPv4, defaultPort);
      } on SocketException {
        return null;
      }
    });
    addTearDown(() => tester.runAsync(() async => blocker?.close()));
    await start(tester);
    await pairAndWait(tester);
    expect(sync.serving, isTrue);
    expect(sync.port, isNot(defaultPort));
    expect((await tester.runAsync(sync.pairingInfo))!.port, sync.port);
    await doneAndStop(tester);
  });

  testWidgets('a session that cannot start shows its error and no QR', (tester) async {
    // A documentation address (TEST-NET-1) is on no interface of this machine: binding it fails.
    await start(tester, bindAddress: InternetAddress('192.0.2.1'));
    await pairAndWait(tester);
    expect(sync.error, isNotNull);
    expect(sync.serving, isFalse);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('Could not send'), findsOneWidget);
    expect(copies(), isEmpty, reason: 'the failed session deletes its copy');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a double click pairs once', (tester) async {
    await start(tester);
    // Two clicks before the next frame: the second one while the first pairing runs.
    final pairButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Pair a phone'));
    pairButton.onPressed!();
    pairButton.onPressed!();
    await pumpUntil(tester, () => find.byType(QrImageView).evaluate().isNotEmpty || sync.error != null);
    expect((sync as _CountingSync).pairs, 1);
    expect(sync.serving, isTrue);
    await doneAndStop(tester);
  });

  testWidgets('showing the QR again for a paired phone serves too', (tester) async {
    await start(tester);
    await pairAndWait(tester);
    await doneAndStop(tester);
    expect(sync.serving, isFalse);

    await tester.tap(find.text('Show QR again'));
    await pumpUntil(tester, () => find.byType(QrImageView).evaluate().isNotEmpty || sync.error != null);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(sync.serving, isTrue);
    expect((await tester.runAsync(sync.pairingInfo))!.port, sync.port);
    await doneAndStop(tester);
  });

  testWidgets('without a network the QR is replaced by a message', (tester) async {
    await start(tester, hosts: const []);
    await tester.tap(find.text('Pair a phone'));
    await settle(tester);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('No network found'), findsOneWidget);
    expect(sync.serving, isFalse, reason: 'no QR, no session');
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
    expect(copies(), isEmpty, reason: 'the copy is deleted');
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
    expect(copies(), isEmpty);
  });

  testWidgets('forget asks for confirmation then removes the pairing', (tester) async {
    await start(tester);
    await pairAndWait(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.textContaining('Phone paired on'), findsOneWidget);
    await tester.tap(find.text('Stop'));
    await settle(tester);

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

/// Pumps (real time for sockets and the database, fake time for widgets) until [done], for at most 5 s.
Future<void> pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(done(), isTrue, reason: 'condition not reached in 5 s');
  await settle(tester);
}

/// Counts pairings (a double click must not pair twice).
class _CountingSync extends PhoneSync {
  _CountingSync(super.db, super.scratch, {super.bindAddress, super.discoveryPort, super.hosts});

  int pairs = 0;

  @override
  Future<void> pair() {
    pairs++;
    return super.pair();
  }
}
