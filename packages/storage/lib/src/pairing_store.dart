import 'dart:math';

import 'package:core/core.dart' show appNow;
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

/// The phone paired with this database (read-only mobile app): one row.
class PairingStore {
  PairingStore(this._db);

  final ExpenseDatabase _db;

  Future<PairedPhoneRow?> current() => _db.select(_db.pairedPhones).getSingleOrNull();

  /// Replaces any pairing with a new database id and a fresh 32-byte secret.
  Future<PairedPhoneRow> pairNew() => _db.transaction(() async {
    final random = Random.secure();
    final row = PairedPhoneRow(
      id: 1,
      databaseId: const Uuid().v4(),
      secret: Uint8List.fromList([for (var i = 0; i < 32; i++) random.nextInt(256)]),
      pairedAt: appNow().toUtc(),
    );
    await _db.into(_db.pairedPhones).insertOnConflictUpdate(row);
    return row;
  });

  Future<void> forget() => _db.delete(_db.pairedPhones).go();

  Future<void> recordSync(String sha256, DateTime at) => (_db.update(
    _db.pairedPhones,
  )..where((p) => p.id.equals(1))).write(PairedPhonesCompanion(lastSyncAt: Value(at), lastSyncHash: Value(sha256)));
}
