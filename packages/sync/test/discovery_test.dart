import 'dart:io';

import 'package:sync/sync.dart';
import 'package:test/test.dart';

void main() {
  final secret = List<int>.generate(32, (i) => i + 1);
  DiscoveryResponder? responder;

  tearDown(() {
    responder?.close();
    responder = null;
  });

  PairingInfo pairing({List<int>? s, String db = 'db-1'}) =>
      PairingInfo(databaseId: db, hosts: ['127.0.0.1'], port: 47820, secret: s ?? secret);

  test('finds the desktop on loopback', () async {
    responder = await DiscoveryResponder.start('db-1', secret, 47822);
    final found = await findDesktop(
      pairing(),
      timeout: const Duration(milliseconds: 500),
      broadcast: InternetAddress.loopbackIPv4,
    );
    expect(found, isNotNull);
    expect(found!.$1, '127.0.0.1');
    expect(found.$2, 47822);
  });

  test('ignores an answer signed with another secret', () async {
    responder = await DiscoveryResponder.start('db-1', List.filled(32, 9), 47822);
    final found = await findDesktop(
      pairing(),
      timeout: const Duration(milliseconds: 300),
      broadcast: InternetAddress.loopbackIPv4,
    );
    expect(found, isNull);
  });

  test('responder ignores a find for another database', () async {
    responder = await DiscoveryResponder.start('db-1', secret, 47822);
    final found = await findDesktop(
      pairing(db: 'db-2'),
      timeout: const Duration(milliseconds: 300),
      broadcast: InternetAddress.loopbackIPv4,
    );
    expect(found, isNull);
  });

  test('nobody answers: null', () async {
    final found = await findDesktop(
      pairing(),
      timeout: const Duration(milliseconds: 200),
      broadcast: InternetAddress.loopbackIPv4,
    );
    expect(found, isNull);
  });
}
