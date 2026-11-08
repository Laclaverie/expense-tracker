import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const authHeader = 'X-Sync-Auth';
const signatureHeader = 'X-Sync-Sig';

const _maxSkew = Duration(minutes: 5);
const _nonceMemory = Duration(minutes: 10);

String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

String _hmac(List<int> secret, String message) => _hex(Hmac(sha256, secret).convert(utf8.encode(message)).bytes);

/// Constant-time string comparison.
bool _constantTimeEquals(String a, String b) {
  var diff = a.length ^ b.length;
  final n = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// 16 random bytes, hex encoded.
String newNonce() {
  final random = Random.secure();
  return _hex(List.generate(16, (_) => random.nextInt(256)));
}

/// Header value `"<millis>.<nonce>.<hmacHex>"`, HMAC-SHA256 over `"$method $path $millis $nonce"`.
String signRequest(List<int> secret, String method, String path, {required DateTime at, required String nonce}) {
  final millis = at.millisecondsSinceEpoch;
  return '$millis.$nonce.${_hmac(secret, '$method $path $millis $nonce')}';
}

/// Checks signed requests: valid HMAC, fresh timestamp, nonce never seen.
class RequestVerifier {
  RequestVerifier(List<int> secret, {DateTime Function()? clock})
    : _secret = List.unmodifiable(secret),
      _clock = clock ?? DateTime.now;

  final List<int> _secret;
  final DateTime Function() _clock;

  /// Nonce -> moment it can be forgotten (request time + memory window).
  final Map<String, DateTime> _seen = {};

  bool verify(String method, String path, String? header) {
    if (header == null) return false;
    final parts = header.split('.');
    if (parts.length != 3) return false;
    final millis = int.tryParse(parts[0]);
    final nonce = parts[1];
    if (millis == null || nonce.isEmpty) return false;

    final now = _clock();
    _seen.removeWhere((_, expiry) => now.isAfter(expiry));

    final expected = _hmac(_secret, '$method $path $millis $nonce');
    if (!_constantTimeEquals(expected, parts[2])) return false;
    final skew = now.millisecondsSinceEpoch - millis;
    if (skew.abs() > _maxSkew.inMilliseconds) return false;
    if (_seen.containsKey(nonce)) return false;
    _seen[nonce] = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).add(_nonceMemory);
    return true;
  }
}

List<int> _bodyMessage(String nonce, List<int> body) => [...utf8.encode(nonce), 0x0A, ...body];

/// Hex HMAC-SHA256 over `utf8(nonce) + 0x0A + body`; [nonce] is the one of the request being answered,
/// so a response cannot be replayed for another request.
String signBody(List<int> secret, List<int> body, {required String nonce}) =>
    _hex(Hmac(sha256, secret).convert(_bodyMessage(nonce, body)).bytes);

bool verifyBody(List<int> secret, List<int> body, String? sig, {required String nonce}) =>
    sig != null && _constantTimeEquals(signBody(secret, body, nonce: nonce), sig);
