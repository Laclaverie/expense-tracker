import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'manifest.dart';
import 'pairing.dart';
import 'signing.dart';

/// What the phone confirms after a complete, verified download.
class SyncAck {
  const SyncAck({required this.sha256, required this.at});

  final String sha256;
  final DateTime at;
}

/// One-shot LAN server offering a database copy to a paired phone.
///
/// Only `GET /manifest`, `GET /database` and `POST /ack` exist, every request must be signed
/// (see [RequestVerifier]) and is checked before any work is done.
class SyncServer {
  SyncServer._(this._server, this._file, this._manifest, this._secret, this._verifier) : port = _server.port {
    _server.listen(_handle, onError: (_) {});
  }

  final HttpServer _server;
  final int port;
  final File _file;
  final Manifest _manifest;
  final List<int> _secret;
  final RequestVerifier _verifier;
  final Completer<SyncAck?> _done = Completer<SyncAck?>();
  Timer? _timer;
  Future<void>? _closing;
  bool _contacted = false;

  /// True once any request reached the server (signed or not): tells "the phone cannot reach us" from
  /// "the phone reached us".
  bool get contacted => _contacted;

  /// Binds [address] (default: all IPv4 interfaces) on [port], or on the next ones up to `port + 10` when
  /// busy. Port 0 lets the system choose. After [window] without a valid ack the server closes and [done]
  /// completes with null.
  static Future<SyncServer> start({
    required File file,
    required Manifest manifest,
    required List<int> secret,
    int port = defaultPort,
    Duration window = const Duration(minutes: 10),
    InternetAddress? address,
  }) async {
    final bindTo = address ?? InternetAddress.anyIPv4;
    final last = port == 0 ? 0 : (port + 10 > 65535 ? 65535 - port : 10);
    for (var i = 0; ; i++) {
      try {
        final http = await HttpServer.bind(bindTo, port + i);
        final server = SyncServer._(http, file, manifest, List.unmodifiable(secret), RequestVerifier(secret));
        server._timer = Timer(window, server.close);
        return server;
      } on SocketException catch (e) {
        if (i >= last || !_inUse(e)) rethrow;
      }
    }
  }

  /// EADDRINUSE on Linux/Android, macOS and Windows (WSAEADDRINUSE, WSAEACCES for exclusive binds).
  static const _addressInUse = {98, 48, 10048, 10013};

  /// Dart reports a second exclusive bind on the same port without an OS code, only with a message.
  static bool _inUse(SocketException e) =>
      _addressInUse.contains(e.osError?.errorCode) || (e.osError?.message.contains('shared flag') ?? false);

  /// The phone's ack, or null when the window ended (or the server was closed) without one.
  Future<SyncAck?> get done => _done.future;

  /// Stops accepting and drops lingering connections. Safe to call more than once.
  Future<void> close() => _closing ??= _shutdown(null);

  Future<void> _shutdown(SyncAck? ack) async {
    _timer?.cancel();
    try {
      await _server.close(force: true);
    } finally {
      if (!_done.isCompleted) _done.complete(ack);
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    _contacted = true;
    try {
      final method = request.method;
      final path = request.uri.path;
      final header = request.headers.value(authHeader);
      if (!_verifier.verify(method, path, header)) {
        await _reply(response, HttpStatus.unauthorized);
        return;
      }
      final nonce = header!.split('.')[1];
      if (method == 'GET' && path == '/manifest') {
        final body = utf8.encode(jsonEncode(_manifest.toJson()));
        response.headers.contentType = ContentType.json;
        response.headers.set(signatureHeader, signBody(_secret, body, nonce: nonce));
        response.contentLength = body.length;
        response.add(body);
        await response.close();
      } else if (method == 'GET' && path == '/database') {
        response.headers.contentType = ContentType.binary;
        response.contentLength = await _file.length();
        await response.addStream(_file.openRead());
        await response.close();
      } else if (method == 'POST' && path == '/ack') {
        await _ack(request);
      } else {
        await _reply(response, HttpStatus.notFound);
      }
    } catch (_) {
      try {
        await _reply(response, HttpStatus.internalServerError);
      } catch (_) {
        // Connection already gone.
      }
    }
  }

  static const _maxAckBody = 1024;

  Future<void> _ack(HttpRequest request) async {
    String? sha;
    if (request.contentLength < 0 || request.contentLength > _maxAckBody) {
      await _reply(request.response, HttpStatus.requestEntityTooLarge);
      return;
    }
    try {
      final bytes = <int>[];
      await for (final chunk in request) {
        bytes.addAll(chunk);
        if (bytes.length > _maxAckBody) {
          await _reply(request.response, HttpStatus.requestEntityTooLarge);
          return;
        }
      }
      final json = jsonDecode(utf8.decode(bytes));
      if (json is Map && json['sha256'] is String) sha = json['sha256'] as String;
    } catch (_) {
      sha = null;
    }
    if (sha == null || sha != _manifest.sha256) {
      await _reply(request.response, HttpStatus.badRequest);
      return;
    }
    await _reply(request.response, HttpStatus.noContent);
    _closing ??= _shutdown(SyncAck(sha256: sha, at: DateTime.now().toUtc()));
  }

  Future<void> _reply(HttpResponse response, int status) async {
    response.statusCode = status;
    response.contentLength = 0;
    await response.close();
  }
}
