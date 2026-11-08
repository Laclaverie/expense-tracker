import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:expense_mobile/phone_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';
import 'package:sync/sync.dart';

const _testDiscoveryPort = 47925;

void main() {
  late Directory root;
  late Directory phoneDir;
  final secret = List<int>.generate(32, (i) => i + 3);
  final cleanups = <Future<void> Function()>[];

  PairingInfo pairing(int port) => PairingInfo(databaseId: 'db-1', hosts: ['127.0.0.1'], port: port, secret: secret);

  Future<File> makeDatabase(String name, String password) async {
    final file = File('${root.path}/$name');
    final db = openEncryptedDatabase(file, password);
    await db.customSelect('select 1').get();
    await db.close();
    return file;
  }

  Manifest manifestOf(File f, {DateTime? at, int schema = ExpenseDatabase.currentSchemaVersion}) => Manifest(
    databaseId: 'db-1',
    schemaVersion: schema,
    size: f.lengthSync(),
    sha256: sha256.convert(f.readAsBytesSync()).toString(),
    createdAt: at ?? DateTime.utc(2026, 11, 8),
  );

  Future<SyncServer> serve(File f, Manifest m) async {
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

  PhoneStore storeWithDiscovery() => PhoneStore(
    phoneDir,
    find: (p) => findDesktop(
      p,
      timeout: const Duration(milliseconds: 300),
      broadcast: InternetAddress.loopbackIPv4,
      port: _testDiscoveryPort,
    ),
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('phone_store_');
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
      // Windows may still hold a handle for a moment.
    }
  });

  test('pairing survives a restart', () {
    PhoneStore(phoneDir).savePairing(pairing(47820));
    final again = PhoneStore(phoneDir).readPairing();
    expect(again, isNotNull);
    expect(again!.databaseId, 'db-1');
    expect(again.hosts, ['127.0.0.1']);
    expect(again.port, 47820);
    expect(again.secret, secret);
  });

  test('no pairing file reads as null, a damaged one too', () {
    expect(PhoneStore(phoneDir).readPairing(), isNull);
    File('${phoneDir.path}/pairing.json').writeAsStringSync('{oops');
    expect(PhoneStore(phoneDir).readPairing(), isNull);
  });

  test('update with the loopback desktop downloads then reports upToDate', () async {
    final source = await makeDatabase('desktop.sqlite', 'pw-one');
    final m = manifestOf(source);
    final server = await serve(source, m);
    final responder = await DiscoveryResponder.start('db-1', secret, server.port, port: _testDiscoveryPort);

    // Stale QR port: discovery must fix it.
    final store = storeWithDiscovery()..savePairing(pairing(1));
    expect(store.localSha256(), isNull);
    final seen = <int>[];
    expect(await store.update(progress: (r, t) => seen.add(r)), UpdateResult.updated);
    expect(store.database.existsSync(), isTrue);
    expect(store.localSha256(), m.sha256);
    expect(seen, isNotEmpty);
    expect(passwordOpens(store.database, 'pw-one'), isTrue);
    expect((await server.done)?.sha256, m.sha256);
    responder.close();

    final again = await serve(source, m);
    final responder2 = await DiscoveryResponder.start('db-1', secret, again.port, port: _testDiscoveryPort);
    addTearDown(responder2.close);
    expect(await store.update(), UpdateResult.upToDate);
  });

  test('falls back to the paired addresses when discovery finds nothing', () async {
    final source = await makeDatabase('desktop.sqlite', 'pw-one');
    final server = await serve(source, manifestOf(source));
    final store = storeWithDiscovery()..savePairing(pairing(server.port));
    expect(await store.update(), UpdateResult.updated);
  });

  test('desktop not reachable throws unreachable', () async {
    final store = PhoneStore(phoneDir, find: (_) async => null)..savePairing(pairing(1));
    await expectLater(
      store.update(),
      throwsA(isA<SyncException>().having((e) => e.problem, 'problem', SyncProblem.unreachable)),
    );
  });

  test('schema mismatch is refused and names both versions', () async {
    final source = await makeDatabase('desktop.sqlite', 'pw-one');
    final server = await serve(source, manifestOf(source, schema: 11));
    final store = PhoneStore(phoneDir, find: (_) async => null)..savePairing(pairing(server.port));
    await expectLater(
      store.update(),
      throwsA(
        isA<SyncException>()
            .having((e) => e.problem, 'problem', SyncProblem.schemaMismatch)
            .having((e) => e.desktopSchema, 'desktopSchema', 11),
      ),
    );
    expect(store.database.existsSync(), isFalse);
  });

  test('a manifest older than the last accepted one is ignored (rollback guard)', () async {
    final source = await makeDatabase('desktop.sqlite', 'pw-one');
    final newer = manifestOf(source, at: DateTime.utc(2026, 11, 8));
    final server = await serve(source, newer);
    final store = PhoneStore(phoneDir, find: (_) async => null)..savePairing(pairing(server.port));
    expect(await store.update(), UpdateResult.updated);

    final old = await makeDatabase('old.sqlite', 'pw-one');
    final stale = manifestOf(old, at: DateTime.utc(2026, 11, 1));
    final staleServer = await serve(old, stale);
    store.savePairing(pairing(staleServer.port));
    final before = store.database.readAsBytesSync();
    expect(await store.update(), UpdateResult.upToDate);
    expect(store.database.readAsBytesSync(), before);
    expect(store.localSha256(), newer.sha256);
  });

  test('new file with other password keeps previous until unlocked', () async {
    final first = await makeDatabase('first.sqlite', 'old-pass');
    final second = await makeDatabase('second.sqlite', 'new-pass');
    final s1 = await serve(first, manifestOf(first, at: DateTime.utc(2026, 11, 1)));
    final store = PhoneStore(phoneDir, find: (_) async => null)..savePairing(pairing(s1.port));
    await store.update();

    final s2 = await serve(second, manifestOf(second, at: DateTime.utc(2026, 11, 8)));
    store.savePairing(pairing(s2.port));
    expect(await store.update(), UpdateResult.updated);

    expect(passwordOpens(store.database, 'old-pass'), isFalse);
    expect(passwordOpens(store.database, 'new-pass'), isTrue);
    expect(store.previous.existsSync(), isTrue);
    expect(passwordOpens(store.previous, 'old-pass'), isTrue);

    store.dropPrevious();
    expect(store.previous.existsSync(), isFalse);
  });

  test('openable uses previous when a crash left no database', () async {
    final f = await makeDatabase('x.sqlite', 'pw');
    final store = PhoneStore(phoneDir);
    expect(store.openable, isNull);
    f.copySync(store.previous.path);
    expect(store.openable?.path, store.previous.path);
    f.copySync(store.database.path);
    expect(store.openable?.path, store.database.path);
  });
}
