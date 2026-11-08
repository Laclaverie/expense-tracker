import 'dart:convert';

const protocolVersion = 1;
const defaultPort = 47820;
const discoveryPort = 47821;

const _prefix = 'expsync:';

/// What the desktop shows as a QR code and the phone scans.
class PairingInfo {
  PairingInfo({required this.databaseId, required this.hosts, required this.port, required List<int> secret})
    : secret = List.unmodifiable(secret);

  final String databaseId;
  final List<String> hosts;
  final int port;
  final List<int> secret;

  String encode() {
    final json = {
      'v': protocolVersion,
      'db': databaseId,
      'hosts': hosts,
      'port': port,
      'secret': base64UrlEncode(secret).replaceAll('=', ''),
    };
    return _prefix + base64UrlEncode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  }

  static PairingInfo decode(String qr) {
    if (!qr.startsWith(_prefix)) throw const FormatException('Not a pairing code');
    try {
      final json = jsonDecode(utf8.decode(_b64(qr.substring(_prefix.length))));
      if (json is! Map) throw const FormatException('Bad pairing payload');
      if (json['v'] != protocolVersion) throw const FormatException('Unsupported pairing version');
      final secret = _b64(json['secret'] as String);
      if (secret.length != 32) throw const FormatException('Bad secret length');
      return PairingInfo(
        databaseId: json['db'] as String,
        hosts: (json['hosts'] as List).cast<String>(),
        port: json['port'] as int,
        secret: secret,
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Bad pairing payload: $e');
    }
  }
}

/// base64url decoding that accepts both padded and unpadded input.
List<int> _b64(String s) => base64Url.decode(base64Url.normalize(s));
