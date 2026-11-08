import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sync/sync.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late File source;
  late Manifest manifest;
  final secret = List<int>.generate(32, (i) => i + 1);
  final random = Random(7);
  final cleanups = <Future<void> Function()>[];

  PairingInfo pairing(int port, {List<int>? secret0, String? db}) =>
      PairingInfo(databaseId: db ?? 'db-1', hosts: ['127.0.0.1'], port: port, secret: secret0 ?? secret);

  Manifest manifestOf(List<int> bytes, {String db = 'db-1', int schema = 10}) => Manifest(
    databaseId: db,
    schemaVersion: schema,
    size: bytes.length,
    sha256: sha256.convert(bytes).toString(),
    createdAt: DateTime.utc(2026, 11, 8),
  );

  Future<SyncServer> startServer({Manifest? m, Duration window = const Duration(minutes: 1), int port = 0}) async {
    final s = await SyncServer.start(
      file: source,
      manifest: m ?? manifest,
      secret: secret,
      port: port,
      window: window,
      address: InternetAddress.loopbackIPv4,
    );
    cleanups.add(s.close);
    return s;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_test');
    final bytes = List<int>.generate(200000, (_) => random.nextInt(256));
    source = File('${dir.path}/source.bin')..writeAsBytesSync(bytes);
    manifest = manifestOf(bytes);
  });

  tearDown(() async {
    for (final c in cleanups) {
      await c();
    }
    cleanups.clear();
    await dir.delete(recursive: true);
  });

  test('downloads, verifies and acks; server closes after ack', () async {
    final server = await startServer();
    final client = SyncClient(pairing(server.port));
    final m = await client.manifest('127.0.0.1', server.port);
    expect(m.sha256, manifest.sha256);
    final target = File('${dir.path}/phone.sqlite')..writeAsStringSync('old');
    var last = 0;
    await client.download('127.0.0.1', server.port, m, target, progress: (r, t) => last = r);
    expect(last, manifest.size);
    expect(target.readAsBytesSync(), source.readAsBytesSync());
    expect(File('${target.path}.previous').readAsStringSync(), 'old');
    expect(File('${target.path}.download').existsSync(), isFalse);
    await client.ack('127.0.0.1', server.port, m.sha256);
    final ack = await server.done;
    expect(ack?.sha256, manifest.sha256);
    await expectLater(client.manifest('127.0.0.1', server.port), throwsA(isA<SyncException>()));
  });

  test('ack with another hash is refused and does not complete', () async {
    final server = await startServer(window: const Duration(milliseconds: 300));
    final client = SyncClient(pairing(server.port));
    await expectLater(client.ack('127.0.0.1', server.port, 'a' * 64), throwsA(isA<SyncException>()));
    expect(await server.done, isNull);
  });

  test('client keeps old file when the stream is cut', () async {
    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    cleanups.add(() => http.close(force: true));
    http.listen((req) async {
      final nonce = req.headers.value(authHeader)!.split('.')[1];
      if (req.uri.path == '/manifest') {
        final body = utf8.encode(jsonEncode(manifest.toJson()));
        req.response.headers.set(signatureHeader, signBody(secret, body, nonce: nonce));
        req.response.add(body);
        await req.response.close();
      } else {
        final bytes = source.readAsBytesSync();
        final socket = await req.response.detachSocket(writeHeaders: false);
        socket.add(ascii.encode('HTTP/1.1 200 OK\r\ncontent-length: ${bytes.length}\r\n\r\n'));
        socket.add(bytes.sublist(0, bytes.length ~/ 2));
        await socket.flush();
        socket.destroy();
      }
    });
    final client = SyncClient(pairing(http.port));
    final m = await client.manifest('127.0.0.1', http.port);
    final target = File('${dir.path}/phone.sqlite')..writeAsStringSync('old');
    await expectLater(
      client.download('127.0.0.1', http.port, m, target),
      throwsA(isA<SyncException>().having((e) => e.problem, 'problem', SyncProblem.incomplete)),
    );
    expect(target.readAsStringSync(), 'old');
    expect(File('${target.path}.download').existsSync(), isFalse);
  });

  test('altered byte is refused', () async {
    final other = source.readAsBytesSync();
    other[100] ^= 1;
    final server = await startServer(m: manifestOf(other));
    final client = SyncClient(pairing(server.port));
    final m = await client.manifest('127.0.0.1', server.port);
    final target = File('${dir.path}/phone.sqlite')..writeAsStringSync('old');
    await expectLater(
      client.download('127.0.0.1', server.port, m, target),
      throwsA(isA<SyncException>().having((e) => e.problem, 'problem', SyncProblem.incomplete)),
    );
    expect(target.readAsStringSync(), 'old');
    expect(File('${target.path}.download').existsSync(), isFalse);
  });

  test('wrong secret is refused', () async {
    final server = await startServer();
    final client = SyncClient(pairing(server.port, secret0: List.filled(32, 9)));
    await expectLater(
      client.manifest('127.0.0.1', server.port),
      throwsA(isA<SyncException>().having((e) => e.problem, 'problem', SyncProblem.notPaired)),
    );
    final raw = HttpClient();
    final req = await raw.getUrl(Uri.parse('http://127.0.0.1:${server.port}/manifest'));
    final res = await req.close();
    expect(res.statusCode, 401);
    await res.drain<void>();
    raw.close();
  });

  test('other database id is not paired', () async {
    final server = await startServer();
    final client = SyncClient(pairing(server.port, db: 'db-2'));
    await expectLater(
      client.manifest('127.0.0.1', server.port),
      throwsA(isA<SyncException>().having((e) => e.problem, 'problem', SyncProblem.notPaired)),
    );
  });

  test('replayed request is refused and unknown route is 404', () async {
    final server = await startServer();
    final raw = HttpClient();
    final header = signRequest(secret, 'GET', '/manifest', at: DateTime.now(), nonce: newNonce());
    Future<int> get(String path, String h) async {
      final req = await raw.getUrl(Uri.parse('http://127.0.0.1:${server.port}$path'));
      req.headers.set(authHeader, h);
      final res = await req.close();
      await res.drain<void>();
      return res.statusCode;
    }

    expect(await get('/manifest', header), 200);
    expect(await get('/manifest', header), 401);
    final h2 = signRequest(secret, 'GET', '/other', at: DateTime.now(), nonce: newNonce());
    expect(await get('/other', h2), 404);
    raw.close();
  });

  test('unreachable server', () async {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();
    final client = SyncClient(pairing(port));
    await expectLater(
      client.manifest('127.0.0.1', port),
      throwsA(isA<SyncException>().having((e) => e.problem, 'problem', SyncProblem.unreachable)),
    );
  });

  test('manifest with same hash needs no download', () {
    expect(needsDownload(manifest, manifest.sha256), isFalse);
    expect(needsDownload(manifest, 'other'), isTrue);
    expect(needsDownload(manifest, null), isTrue);
  });

  test('schema mismatch refuses before download', () {
    final newer = manifestOf([1, 2, 3], schema: 11);
    expect(
      () => checkSchema(newer, 10),
      throwsA(isA<SyncException>().having((e) => e.problem, 'problem', SyncProblem.schemaMismatch)),
    );
    checkSchema(newer, 11);
    try {
      checkSchema(newer, 10);
    } on SyncException catch (e) {
      expect([e.desktopSchema, e.appSchema], [11, 10]);
    }
    expect(
      () => checkSchema(newer, 12),
      throwsA(
        isA<SyncException>()
            .having((e) => e.problem, 'problem', SyncProblem.schemaMismatch)
            .having((e) => e.desktopSchema, 'desktop', 11)
            .having((e) => e.appSchema, 'app', 12),
      ),
    );
  });

  test('a stalled connection does not keep the server alive past the window', () async {
    final server = await startServer(window: const Duration(milliseconds: 200));
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, server.port);
    cleanups.add(() async => socket.destroy());
    socket.add(ascii.encode('GET /database HTTP/1.1\r\nhost: x\r\n'));
    await socket.flush();
    final ack = await server.done.timeout(const Duration(seconds: 3));
    expect(ack, isNull);
  });

  test('oversized ack body is refused with 413', () async {
    final server = await startServer(window: const Duration(seconds: 5));
    final raw = HttpClient();
    final header = signRequest(secret, 'POST', '/ack', at: DateTime.now(), nonce: newNonce());
    final req = await raw.postUrl(Uri.parse('http://127.0.0.1:${server.port}/ack'));
    req.headers.set(authHeader, header);
    req.add(List.filled(2000, 65));
    final res = await req.close();
    expect(res.statusCode, 413);
    await res.drain<void>();
    raw.close(force: true);
  });

  test('window timeout closes the server and done is null', () async {
    final server = await startServer(window: const Duration(milliseconds: 200));
    expect(await server.done, isNull);
    final client = SyncClient(pairing(server.port));
    await expectLater(client.manifest('127.0.0.1', server.port), throwsA(isA<SyncException>()));
  });

  test('busy port moves to the next one', () async {
    final first = await startServer();
    final second = await startServer(port: first.port);
    expect(second.port, greaterThan(first.port));
    expect(second.port, lessThanOrEqualTo(first.port + 10));
  });
}
