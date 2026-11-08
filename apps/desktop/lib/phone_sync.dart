import 'dart:async';
import 'dart:io';

import 'package:core/core.dart' show appNow;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:storage/storage.dart';
import 'package:sync/sync.dart';

/// The paired phone and the one-shot transfer of the database to it.
///
/// [send] copies the open database (`VACUUM INTO`: the copy keeps the cipher) into [scratch], offers it on the
/// LAN to the phone and deletes it as soon as the session ends (ack, timeout or [stop]).
class PhoneSync extends ChangeNotifier {
  PhoneSync(
    this._db,
    this.scratch, {
    this.bindAddress,
    this.discoveryPort,
    this.window = const Duration(minutes: 10),
    this.hintAfter = const Duration(minutes: 2),
    this.hosts = lanAddresses,
  }) : store = PairingStore(_db) {
    // A copy left by a session that never ended (the app was quit while serving).
    _deleteCopy();
  }

  final ExpenseDatabase _db;

  /// Where the temporary copy lives (the app's data folder, never next to the backups).
  final Directory scratch;

  /// Test hooks: loopback only (no firewall prompt) and a private discovery port.
  final InternetAddress? bindAddress;
  final int? discoveryPort;

  /// How long the phone has to come, and when to suggest checking the network.
  final Duration window;
  final Duration hintAfter;

  /// Private IPv4 addresses to put in the QR code (empty: no network).
  final Future<List<String>> Function() hosts;

  final PairingStore store;

  PairedPhoneRow? _phone;
  bool _loaded = false;
  bool _serving = false;
  bool _disposed = false;

  /// Bumped by [send] and [stop]: a [send] still preparing when the session changed gives up.
  int _session = 0;
  DateTime? _syncedAt;
  Object? _error;
  SyncServer? _server;
  DiscoveryResponder? _responder;
  final Stopwatch _elapsed = Stopwatch();

  File get _copy => File('${scratch.path}${Platform.pathSeparator}phone-copy.sqlite');

  /// The pairing, null when none (or not loaded yet: see [loaded]).
  PairedPhoneRow? get phone => _phone;
  bool get loaded => _loaded;
  bool get serving => _serving;

  /// Set when a session ended with the phone's confirmation; kept until the next [send].
  DateTime? get syncedAt => _syncedAt;
  Object? get error => _error;

  /// The port the server listens on during a session.
  int? get port => _server?.port;

  /// True once the phone reached the server in this session.
  bool get contacted => _server?.contacted ?? false;

  Duration get remaining {
    final left = window - _elapsed.elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// No request after [hintAfter]: the phone is probably blocked (Wi-Fi, firewall).
  bool get showFirewallHint => _serving && !contacted && _elapsed.elapsed >= hintAfter;

  Future<void> refresh() async {
    _phone = await store.current();
    _loaded = true;
    _notify();
  }

  Future<PairingInfo?> pairingInfo() async {
    final p = _phone ?? await store.current();
    if (p == null) return null;
    return PairingInfo(databaseId: p.databaseId, hosts: await hosts(), port: defaultPort, secret: p.secret);
  }

  Future<void> pair() async {
    await stop();
    _phone = await store.pairNew();
    _loaded = true;
    _syncedAt = null;
    _error = null;
    _notify();
  }

  Future<void> forget() async {
    await stop();
    await store.forget();
    _phone = null;
    _syncedAt = null;
    _error = null;
    _notify();
  }

  /// Starts one session; returns once the phone is being waited for. One session at a time.
  Future<void> send() async {
    if (_serving) return;
    final p = _phone ?? await store.current();
    if (p == null) return;
    final session = ++_session;
    bool live() => session == _session && !_disposed;
    _serving = true;
    _syncedAt = null;
    _error = null;
    _elapsed
      ..reset()
      ..start();
    _notify();
    SyncServer? server;
    DiscoveryResponder? responder;
    try {
      scratch.createSync(recursive: true);
      _deleteCopy();
      await _db.customStatement("VACUUM INTO '${_copy.path.replaceAll("'", "''")}'");
      if (!live()) {
        await _abandon(null, null);
        return;
      }
      final digest = await sha256.bind(_copy.openRead()).first;
      if (!live()) {
        await _abandon(null, null);
        return;
      }
      final size = await _copy.length();
      if (!live()) {
        await _abandon(null, null);
        return;
      }
      final manifest = Manifest(
        databaseId: p.databaseId,
        schemaVersion: ExpenseDatabase.currentSchemaVersion,
        size: size,
        sha256: digest.toString(),
        createdAt: appNow().toUtc(),
      );
      server = await SyncServer.start(
        file: _copy,
        manifest: manifest,
        secret: p.secret,
        window: window,
        address: bindAddress,
      );
      if (!live()) {
        await _abandon(server, null);
        return;
      }
      try {
        responder = await DiscoveryResponder.start(p.databaseId, p.secret, server.port, port: discoveryPort);
      } on SocketException {
        // Discovery is a convenience (the QR holds the addresses): carry on without it.
      }
      if (!live()) {
        await _abandon(server, responder);
        return;
      }
      _server = server;
      _responder = responder;
      unawaited(_finish(server));
    } catch (e) {
      if (!live()) {
        await _abandon(server, responder);
        return;
      }
      _error = e;
      await _end();
    }
  }

  /// A session stopped (or the object disposed) while it was still being prepared: undo what it made.
  Future<void> _abandon(SyncServer? server, DiscoveryResponder? responder) async {
    responder?.close();
    try {
      await server?.close();
    } catch (_) {
      // Already closed.
    }
    // Unless a newer session is already serving it.
    if (!_serving) _deleteCopy();
  }

  Future<void> _finish(SyncServer server) async {
    final ack = await server.done;
    if (!identical(_server, server)) return;
    try {
      if (ack != null) {
        final at = appNow().toUtc();
        if (!_disposed) await store.recordSync(ack.sha256, at);
        _syncedAt = at;
        if (!_disposed) _phone = await store.current();
      }
    } catch (e) {
      _error = e;
    }
    await _end();
  }

  /// Ends the session: closes the server and discovery, deletes the copy.
  Future<void> stop() async {
    _session++;
    final server = _server;
    if (server != null) await server.close();
    await _end();
  }

  Future<void> _end() async {
    _elapsed.stop();
    final server = _server;
    _server = null;
    _responder?.close();
    _responder = null;
    try {
      await server?.close();
    } catch (_) {
      // Already closed.
    }
    _deleteCopy();
    _serving = false;
    _notify();
  }

  void _deleteCopy() {
    for (final f in [_copy, File('${_copy.path}-wal'), File('${_copy.path}-shm'), File('${_copy.path}-journal')]) {
      try {
        if (f.existsSync()) f.deleteSync();
      } on FileSystemException {
        // Still open on Windows for a moment; the next send removes it.
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _server?.close();
    _responder?.close();
    _server = null;
    _responder = null;
    _deleteCopy();
    super.dispose();
  }
}
