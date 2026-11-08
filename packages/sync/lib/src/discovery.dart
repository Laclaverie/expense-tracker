import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'pairing.dart';
import 'signing.dart';

/// Answers UDP "find" messages for one database, so a phone can locate the desktop when its IP changed.
class DiscoveryResponder {
  DiscoveryResponder._(this._socket, this._databaseId, this._secret, this._serverPort) {
    _socket.listen(_onEvent, onError: (_) {});
  }

  final RawDatagramSocket _socket;
  final String _databaseId;
  final List<int> _secret;
  final int _serverPort;

  /// Listens on UDP [discoveryPort] (override [port] for tests).
  static Future<DiscoveryResponder> start(String databaseId, List<int> secret, int serverPort, {int? port}) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port ?? discoveryPort);
    return DiscoveryResponder._(socket, databaseId, List.unmodifiable(secret), serverPort);
  }

  void close() => _socket.close();

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket.receive();
    if (datagram == null) return;
    try {
      final json = jsonDecode(utf8.decode(datagram.data));
      if (json is! Map || json['v'] != protocolVersion || json['find'] != _databaseId) return;
      final nonce = json['nonce'];
      if (nonce is! String || nonce.isEmpty || nonce.length > 64) return;
      final answer = _answerBody(_databaseId, _serverPort);
      final sig = signBody(_secret, utf8.encode(answer), nonce: nonce);
      final message = jsonEncode({'v': protocolVersion, 'db': _databaseId, 'port': _serverPort, 'sig': sig});
      _socket.send(utf8.encode(message), datagram.address, datagram.port);
    } catch (_) {
      // Not for us.
    }
  }
}

String _answerBody(String databaseId, int port) => jsonEncode({'v': protocolVersion, 'db': databaseId, 'port': port});

/// Broadcasts a find message and returns the host and port of the first correctly signed answer, or null.
/// [broadcast] defaults to 255.255.255.255; [port] overrides [discoveryPort] (tests).
Future<(String host, int port)?> findDesktop(
  PairingInfo p, {
  Duration timeout = const Duration(seconds: 2),
  InternetAddress? broadcast,
  int? port,
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final result = Completer<(String, int)?>();
  final nonce = newNonce();
  Timer? resend;
  final timer = Timer(timeout, () {
    if (!result.isCompleted) result.complete(null);
  });
  socket.listen((event) {
    if (event != RawSocketEvent.read || result.isCompleted) return;
    final datagram = socket.receive();
    if (datagram == null) return;
    try {
      final json = jsonDecode(utf8.decode(datagram.data));
      if (json is! Map || json['v'] != protocolVersion || json['db'] != p.databaseId) return;
      final answerPort = json['port'];
      final sig = json['sig'];
      if (answerPort is! int || answerPort < 1 || answerPort > 65535 || sig is! String) return;
      if (!verifyBody(p.secret, utf8.encode(_answerBody(p.databaseId, answerPort)), sig, nonce: nonce)) return;
      result.complete((datagram.address.address, answerPort));
    } catch (_) {
      // Ignore garbage.
    }
  }, onError: (_) {});
  try {
    socket.broadcastEnabled = true;
    final find = jsonEncode({'v': protocolVersion, 'find': p.databaseId, 'nonce': nonce});
    final to = broadcast ?? InternetAddress('255.255.255.255');
    final bytes = utf8.encode(find);
    var sent = 1;
    resend = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (result.isCompleted || ++sent > 3) return t.cancel();
      try {
        socket.send(bytes, to, port ?? discoveryPort);
      } catch (_) {
        // Network went away; the timeout ends the search.
      }
    });
    socket.send(bytes, to, port ?? discoveryPort);
    return await result.future;
  } on SocketException {
    return null;
  } finally {
    timer.cancel();
    resend?.cancel();
    socket.close();
  }
}
