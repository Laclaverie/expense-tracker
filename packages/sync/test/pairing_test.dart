import 'dart:convert';

import 'package:sync/sync.dart';
import 'package:test/test.dart';

void main() {
  final secret = List<int>.generate(32, (i) => i);

  String qr(Map<String, Object?> json) => 'expsync:${base64Url.encode(utf8.encode(jsonEncode(json)))}';

  Map<String, Object?> valid({int v = 1, List<int>? sec}) => {
    'v': v,
    'db': 'db-1',
    'hosts': ['192.168.1.20'],
    'port': 47820,
    'secret': base64Url.encode(sec ?? secret).replaceAll('=', ''),
  };

  test('round trip', () {
    final info = PairingInfo(databaseId: 'db-1', hosts: ['192.168.1.20', '10.0.0.5'], port: 47820, secret: secret);
    final back = PairingInfo.decode(info.encode());
    expect(back.databaseId, 'db-1');
    expect(back.hosts, ['192.168.1.20', '10.0.0.5']);
    expect(back.port, 47820);
    expect(back.secret, secret);
    expect(info.encode(), startsWith('expsync:'));
  });

  test('decodes padded base64url too', () {
    final padded = 'expsync:${base64Url.encode(utf8.encode(jsonEncode(valid())))}';
    expect(PairingInfo.decode(padded).secret, secret);
  });

  test('other prefix throws', () {
    expect(() => PairingInfo.decode('otherapp:abc'), throwsFormatException);
  });
  test('31-byte secret throws', () {
    expect(() => PairingInfo.decode(qr(valid(sec: secret.sublist(0, 31)))), throwsFormatException);
  });
  test('version 2 throws', () {
    expect(() => PairingInfo.decode(qr(valid(v: 2))), throwsFormatException);
  });
  test('garbage throws FormatException', () {
    expect(() => PairingInfo.decode('expsync:!!!'), throwsFormatException);
  });
}
