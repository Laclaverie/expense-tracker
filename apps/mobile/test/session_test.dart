import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:expense_mobile/l10n/app_localizations.dart';
import 'package:expense_mobile/phone_store.dart';
import 'package:expense_mobile/session.dart';
import 'package:expense_mobile/sync_banner.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';
import 'package:sync/sync.dart';

/// A store whose transfer a test finishes by hand.
class _SlowStore extends PhoneStore {
  _SlowStore(super.dir);
  final release = Completer<void>();

  @override
  Future<UpdateResult> update({SyncClient? client, void Function(int received, int total)? progress}) async {
    await release.future;
    return UpdateResult.updated;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory root;
  late Directory phoneDir;
  final secret = List<int>.generate(32, (i) => i + 9);
  final cleanups = <Future<void> Function()>[];
  var opened = 0;

  Future<File> makeDatabase(String name, String password) async {
    final file = File('${root.path}/$name');
    final db = openEncryptedDatabase(file, password);
    await db.customSelect('select 1').get();
    await db.close();
    return file;
  }

  Future<SyncServer> serve(File f, DateTime at) async {
    final m = Manifest(
      databaseId: 'db-1',
      schemaVersion: ExpenseDatabase.currentSchemaVersion,
      size: f.lengthSync(),
      sha256: sha256.convert(f.readAsBytesSync()).toString(),
      createdAt: at,
    );
    final s = await SyncServer.start(
      file: f,
      manifest: m,
      secret: secret,
      port: 0,
      address: InternetAddress.loopbackIPv4,
    );
    cleanups.add(s.close);
    return s;
  }

  PairingInfo pairing(int port) => PairingInfo(databaseId: 'db-1', hosts: ['127.0.0.1'], port: port, secret: secret);

  Session sessionFor(PhoneStore store) => Session(
    store,
    check: (path, password) async => passwordOpens(File(path), password),
    open: (file, password) {
      opened++;
      return ExpenseDatabase(NativeDatabase.memory(), readOnly: true);
    },
  );

  setUp(() {
    HttpOverrides.global = null;
    opened = 0;
    root = Directory.systemTemp.createTempSync('session_test_');
    phoneDir = Directory('${root.path}/phone')..createSync();
  });

  tearDown(() async {
    for (final c in cleanups) {
      await c();
    }
    cleanups.clear();
    try {
      root.deleteSync(recursive: true);
    } on FileSystemException {
      // Best effort.
    }
  });

  test('sync closes, swaps and reopens with the same password', () async {
    final first = await makeDatabase('first.sqlite', 'pw');
    final second = await makeDatabase('second.sqlite', 'pw');
    final store = PhoneStore(phoneDir, find: (_) async => null);
    final s1 = await serve(first, DateTime.utc(2026, 11, 1));
    store.savePairing(pairing(s1.port));
    await store.update();

    final session = sessionFor(store);
    expect(await session.unlock('pw'), UnlockOutcome.opened);
    expect(opened, 1);

    final s2 = await serve(second, DateTime.utc(2026, 11, 8));
    store.savePairing(pairing(s2.port));
    expect(await session.sync(), UpdateResult.updated);
    expect(session.unlocked, isTrue);
    expect(session.usingPrevious, isFalse);
    expect(opened, 2);
    expect(store.previous.existsSync(), isFalse);
  });

  test('sync onto a file with another password keeps the previous copy open', () async {
    final first = await makeDatabase('first.sqlite', 'old-pass');
    final second = await makeDatabase('second.sqlite', 'new-pass');
    final store = PhoneStore(phoneDir, find: (_) async => null);
    final s1 = await serve(first, DateTime.utc(2026, 11, 1));
    store.savePairing(pairing(s1.port));
    await store.update();
    final session = sessionFor(store);
    await session.unlock('old-pass');

    final s2 = await serve(second, DateTime.utc(2026, 11, 8));
    store.savePairing(pairing(s2.port));
    await session.sync();

    expect(session.unlocked, isTrue);
    expect(session.usingPrevious, isTrue);
    expect(store.previous.existsSync(), isTrue);
    expect(await session.unlock('new-pass'), UnlockOutcome.opened);
    expect(session.usingPrevious, isFalse);
    expect(store.previous.existsSync(), isFalse);
  });

  test('a lock during a running sync wins: nothing is reopened', () async {
    final f = await makeDatabase('x.sqlite', 'pw');
    f.copySync('${phoneDir.path}/expenses.sqlite');
    final store = _SlowStore(phoneDir);
    final session = sessionFor(store);
    await session.unlock('pw');
    expect(opened, 1);

    final running = session.sync();
    await Future<void>.delayed(Duration.zero);
    await session.lock();
    store.release.complete();
    await running;

    expect(session.unlocked, isFalse);
    expect(session.db, isNull);
    expect(opened, 1, reason: 'no reopen after the lock');
    expect(await session.unlock('wrong'), UnlockOutcome.wrong);
  });

  test('a lock while the password is being checked does not open the database', () async {
    final f = await makeDatabase('x.sqlite', 'pw');
    f.copySync('${phoneDir.path}/expenses.sqlite');
    final gate = Completer<void>();
    final session = Session(
      PhoneStore(phoneDir),
      check: (path, password) async {
        await gate.future;
        return true;
      },
      open: (file, password) {
        opened++;
        return ExpenseDatabase(NativeDatabase.memory(), readOnly: true);
      },
    );
    final pending = session.unlock('pw');
    await session.lock();
    gate.complete();
    expect(await pending, UnlockOutcome.wrong);
    expect(opened, 0);
  });

  testWidgets('syncMessage covers every problem and both update directions', (tester) async {
    late AppLocalizations l;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            l = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();
    expect(syncMessage(l, const SyncException(SyncProblem.unreachable)), l.errUnreachable);
    expect(syncMessage(l, const SyncException(SyncProblem.notPaired)), l.errNotPaired);
    expect(syncMessage(l, const SyncException(SyncProblem.incomplete)), l.errIncomplete);
    const v = ExpenseDatabase.currentSchemaVersion;
    expect(syncMessage(l, const SyncException(SyncProblem.schemaMismatch, null, v + 1, v)), l.errUpdatePhone);
    expect(syncMessage(l, const SyncException(SyncProblem.schemaMismatch, null, v - 1, v)), l.errUpdateDesktop);
    expect(l.errUpdatePhone, contains('phone app'));
    expect(l.errUpdateDesktop, contains('desktop app'));
  });
}
