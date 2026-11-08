import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'manifest.dart';
import 'pairing.dart';
import 'signing.dart';

enum SyncProblem { unreachable, notPaired, incomplete, schemaMismatch }

class SyncException implements Exception {
  const SyncException(this.problem, [this.detail]);

  final SyncProblem problem;
  final String? detail;

  @override
  String toString() => 'SyncException(${problem.name}${detail == null ? '' : ': $detail'})';
}

/// True when the desktop offers a copy different from the phone's ([localSha256] null = none yet).
bool needsDownload(Manifest m, String? localSha256) => localSha256 != m.sha256;

/// Refuses a database written by a newer schema than the app knows.
void checkSchema(Manifest m, int appSchemaVersion) {
  if (m.schemaVersion > appSchemaVersion) {
    throw SyncException(SyncProblem.schemaMismatch, 'database v${m.schemaVersion}, app v$appSchemaVersion');
  }
}

/// Phone side of the LAN transfer.
class SyncClient {
  // ignore: prefer_initializing_formals
  SyncClient(this.pairing, {HttpClient? http}) : _http = http;

  final PairingInfo pairing;
  final HttpClient? _http;

  static const _connectTimeout = Duration(seconds: 5);
  static const _idleTimeout = Duration(seconds: 30);

  HttpClient _newClient() => _http ?? (HttpClient()..connectionTimeout = _connectTimeout);

  void _release(HttpClient c) {
    if (_http == null) c.close(force: true);
  }

  Future<HttpClientResponse> _send(
    HttpClient client,
    String method,
    String host,
    int port,
    String path,
    String nonce, {
    List<int>? body,
  }) async {
    try {
      final request = await client
          .openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path))
          .timeout(_connectTimeout);
      request.headers.set(authHeader, signRequest(pairing.secret, method, path, at: DateTime.now(), nonce: nonce));
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.contentLength = body.length;
        request.add(body);
      }
      return await request.close().timeout(_connectTimeout);
    } on SocketException catch (e) {
      throw SyncException(SyncProblem.unreachable, e.message);
    } on TimeoutException {
      throw const SyncException(SyncProblem.unreachable, 'timeout');
    } on HttpException catch (e) {
      throw SyncException(SyncProblem.unreachable, e.message);
    } on TlsException catch (e) {
      throw SyncException(SyncProblem.unreachable, e.message);
    }
  }

  Future<Manifest> manifest(String host, int port) async {
    final client = _newClient();
    try {
      final nonce = newNonce();
      final response = await _send(client, 'GET', host, port, '/manifest', nonce);
      if (response.statusCode == HttpStatus.unauthorized) {
        await response.drain<void>();
        throw const SyncException(SyncProblem.notPaired, 'refused by the desktop');
      }
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw SyncException(SyncProblem.unreachable, 'status ${response.statusCode}');
      }
      final bytes = <int>[];
      try {
        await for (final chunk in response.timeout(_idleTimeout)) {
          bytes.addAll(chunk);
          if (bytes.length > 65536) throw const SyncException(SyncProblem.notPaired, 'manifest too large');
        }
      } on SocketException catch (e) {
        throw SyncException(SyncProblem.unreachable, e.message);
      } on HttpException catch (e) {
        throw SyncException(SyncProblem.unreachable, e.message);
      } on TimeoutException {
        throw const SyncException(SyncProblem.unreachable, 'timeout');
      }
      if (!verifyBody(pairing.secret, bytes, response.headers.value(signatureHeader), nonce: nonce)) {
        throw const SyncException(SyncProblem.notPaired, 'bad signature');
      }
      final Manifest m;
      try {
        final json = jsonDecode(utf8.decode(bytes));
        if (json is! Map<String, dynamic>) throw const FormatException('not an object');
        m = Manifest.fromJson(json);
      } on FormatException catch (e) {
        throw SyncException(SyncProblem.notPaired, 'bad manifest: ${e.message}');
      }
      if (m.databaseId != pairing.databaseId) {
        throw const SyncException(SyncProblem.notPaired, 'other database');
      }
      return m;
    } finally {
      _release(client);
    }
  }

  /// Downloads to `<target>.download`, checks size and SHA-256 against [m], then moves the previous [target]
  /// to `<target>.previous` and the download to [target]. Any failure leaves [target] untouched.
  Future<void> download(
    String host,
    int port,
    Manifest m,
    File target, {
    void Function(int received, int total)? progress,
  }) async {
    final partial = File('${target.path}.download');
    final client = _newClient();
    IOSink? sink;
    try {
      final response = await _send(client, 'GET', host, port, '/database', newNonce());
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw SyncException(SyncProblem.incomplete, 'status ${response.statusCode}');
      }
      Digest? digest;
      final hash = sha256.startChunkedConversion(ChunkedConversionSink<Digest>.withCallback((l) => digest = l.single));
      sink = partial.openWrite();
      var received = 0;
      await for (final chunk in response.timeout(_idleTimeout)) {
        received += chunk.length;
        if (received > m.size) throw const SyncException(SyncProblem.incomplete, 'more bytes than announced');
        hash.add(chunk);
        sink.add(chunk);
        progress?.call(received, m.size);
      }
      hash.close();
      await sink.flush();
      await sink.close();
      sink = null;
      if (received != m.size) throw SyncException(SyncProblem.incomplete, 'got $received of ${m.size} bytes');
      if (digest.toString() != m.sha256) throw const SyncException(SyncProblem.incomplete, 'checksum differs');
      await _swap(partial, target);
    } on SyncException {
      await _discard(sink, partial);
      rethrow;
    } catch (e) {
      await _discard(sink, partial);
      throw SyncException(SyncProblem.incomplete, '$e');
    } finally {
      _release(client);
    }
  }

  Future<void> _discard(IOSink? sink, File partial) async {
    try {
      await sink?.close();
    } catch (_) {
      // Already broken.
    }
    try {
      if (await partial.exists()) await partial.delete();
    } catch (_) {
      // Best effort.
    }
  }

  Future<void> _swap(File partial, File target) async {
    final previous = File('${target.path}.previous');
    final hadTarget = await target.exists();
    if (hadTarget) {
      if (await previous.exists()) await previous.delete();
      await target.rename(previous.path);
    }
    try {
      await partial.rename(target.path);
    } catch (_) {
      if (hadTarget) await previous.rename(target.path);
      rethrow;
    }
  }

  Future<void> ack(String host, int port, String sha256) async {
    final client = _newClient();
    try {
      final response = await _send(
        client,
        'POST',
        host,
        port,
        '/ack',
        newNonce(),
        body: utf8.encode(jsonEncode({'sha256': sha256})),
      );
      await response.drain<void>();
      if (response.statusCode == HttpStatus.unauthorized) throw const SyncException(SyncProblem.notPaired);
      if (response.statusCode != HttpStatus.noContent) {
        throw SyncException(SyncProblem.unreachable, 'ack refused: status ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw SyncException(SyncProblem.unreachable, e.message);
    } finally {
      _release(client);
    }
  }
}
