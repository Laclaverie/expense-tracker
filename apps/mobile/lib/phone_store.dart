import 'dart:convert';
import 'dart:io';

import 'package:sync/sync.dart';
import 'package:storage/storage.dart';

enum UpdateResult { upToDate, updated }

/// Finds the desktop on the LAN (tests pass one aimed at loopback).
typedef DesktopFinder = Future<(String host, int port)?> Function(PairingInfo pairing);

/// What the desktop offers and where to fetch it.
class Offer {
  const Offer(this.host, this.port, this.manifest);
  final String host;
  final int port;
  final Manifest manifest;
}

/// The phone's files in its private app folder: the pairing, the encrypted database copy, the copy before
/// the last download and the last accepted manifest. The password is never stored.
class PhoneStore {
  PhoneStore(this.dir, {DesktopFinder? find}) : _find = find ?? ((p) => findDesktop(p));

  final Directory dir;
  final DesktopFinder _find;

  File get database => File('${dir.path}/expenses.sqlite');
  File get previous => File('${dir.path}/expenses.sqlite.previous');
  File get _pairing => File('${dir.path}/pairing.json');
  File get _last => File('${dir.path}/last.json');

  /// The file to unlock: [database], or [previous] when a crash happened between the two renames of a
  /// download.
  File? get openable {
    if (database.existsSync()) return database;
    if (previous.existsSync()) return previous;
    return null;
  }

  PairingInfo? readPairing() {
    try {
      final json = jsonDecode(_pairing.readAsStringSync());
      return PairingInfo.decode((json as Map)['qr'] as String);
    } catch (_) {
      return null;
    }
  }

  void savePairing(PairingInfo p) {
    dir.createSync(recursive: true);
    _pairing.writeAsStringSync(jsonEncode({'qr': p.encode()}));
  }

  /// Forgets the pairing and the data files (to pair with another desktop).
  void clear() {
    for (final f in [_pairing, _last, database, previous]) {
      if (f.existsSync()) f.deleteSync();
    }
  }

  Map<String, Object?>? _readLast() {
    try {
      final json = jsonDecode(_last.readAsStringSync());
      return json is Map<String, Object?> ? json : null;
    } catch (_) {
      return null;
    }
  }

  String? localSha256() => _readLast()?['sha256'] as String?;

  /// When the last accepted copy was made on the desktop.
  DateTime? dataDate() {
    final s = _readLast()?['createdAt'];
    return s is String ? DateTime.tryParse(s) : null;
  }

  void dropPrevious() {
    if (previous.existsSync()) previous.deleteSync();
  }

  /// The desktop's newer copy, or null when the phone is up to date. A manifest older than the last accepted
  /// one is ignored (a replayed or stale answer must not roll the data back). Throws [SyncException].
  Future<Offer?> available({SyncClient? client}) async {
    final pairing = readPairing();
    if (pairing == null) throw const SyncException(SyncProblem.notPaired, 'not paired');
    final c = client ?? SyncClient(pairing);
    final targets = <(String, int)>[];
    final found = await _find(pairing);
    if (found != null) targets.add(found);
    for (final h in pairing.hosts) {
      targets.add((h, pairing.port));
    }
    SyncException? unreachable;
    for (final (host, port) in targets) {
      final Manifest m;
      try {
        m = await c.manifest(host, port);
      } on SyncException catch (e) {
        if (e.problem != SyncProblem.unreachable) rethrow;
        unreachable = e;
        continue;
      }
      checkSchema(m, ExpenseDatabase.currentSchemaVersion);
      final last = dataDate();
      if (last != null && m.createdAt.isBefore(last)) return null;
      if (!needsDownload(m, localSha256())) return null;
      return Offer(host, port, m);
    }
    throw unreachable ?? const SyncException(SyncProblem.unreachable, 'no address');
  }

  Future<UpdateResult> update({SyncClient? client, void Function(int received, int total)? progress}) async {
    final pairing = readPairing();
    if (pairing == null) throw const SyncException(SyncProblem.notPaired, 'not paired');
    final c = client ?? SyncClient(pairing);
    final offer = await available(client: c);
    if (offer == null) return UpdateResult.upToDate;
    dir.createSync(recursive: true);
    await c.download(offer.host, offer.port, offer.manifest, database, progress: progress);
    _last.writeAsStringSync(
      jsonEncode({'sha256': offer.manifest.sha256, 'createdAt': offer.manifest.createdAt.toIso8601String()}),
    );
    try {
      await c.ack(offer.host, offer.port, offer.manifest.sha256);
    } on SyncException {
      // The data is in place; the desktop just keeps waiting until its window ends.
    }
    return UpdateResult.updated;
  }
}
