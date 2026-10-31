import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'database.dart';
import 'dev_copy.dart' show devCopyTable;
import 'encryption.dart';

/// Why a file can't be restored.
enum RestoreProblem {
  /// Not an SQLite database.
  notADatabase,

  /// Written by a newer version of the app: opening it here could break it.
  newerVersion,

  /// An SQLite database, but not this app's.
  notExpenses,

  /// Encrypted, and neither the current password nor the one given opens it
  /// (a copy made before the password changed, or not a database at all).
  wrongPassword,

  /// An anonymized developer copy ([writeDevCopy]): never someone's data.
  devCopy,
}

class RestoreException implements Exception {
  const RestoreException(this.problem);

  final RestoreProblem problem;

  @override
  String toString() => 'RestoreException(${problem.name})';
}

/// What [Backups.prepare] did.
class PrepareResult {
  const PrepareResult({required this.converted, required this.copiesEncrypted, this.migrationCopy});

  /// The database was plaintext (made before encryption) and is now encrypted.
  final bool converted;

  /// Plaintext automatic copies (or staged restore) now encrypted.
  final int copiesEncrypted;

  /// Copy made because this version migrates the database.
  final File? migrationCopy;
}

/// One automatic copy in [Backups.folder].
class BackupFile {
  const BackupFile(this.file, this.date, this.reason);

  final File file;

  /// Local time the copy was made.
  final DateTime date;

  /// `before-import`, `before-v7` (schema migration), `before-restore`, `before-categories`.
  final String reason;
}

/// Copies of the database file, so an import, an app update (schema
/// migration) or a restore can be undone. Automatic copies go to `backups/`
/// next to the database, the last [keep] are kept; manual ones go where the
/// user chooses and are never deleted.
///
/// With a [password] (the app always has one, set once unlocked), the
/// database and every copy are encrypted with it ([encryptInPlace]); a
/// restored file always ends up encrypted with the current password.
class Backups {
  Backups(this.databaseFile, {this.keep = 15, this.password, DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final File databaseFile;
  final int keep;

  /// The database password; null only in tests of plaintext files.
  String? password;
  final DateTime Function() _now;

  Directory get folder => Directory('${databaseFile.parent.path}${Platform.pathSeparator}backups');

  /// Staged by [stageRestore], applied by [applyPendingRestore] at the next start.
  File get _pending => File('${databaseFile.path}.restore');

  static final _name = RegExp(r'^expenses-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})(?:-\d+)?-(.+)\.sqlite$');

  /// The schema version stored in an SQLite file's header (`PRAGMA user_version`),
  /// or null when [file] is missing or not an SQLite database. Reads the
  /// header only: the file is never opened as a database.
  static int? schemaVersionOf(File file) {
    if (!file.existsSync()) return null;
    final raf = file.openSync();
    try {
      final header = raf.readSync(64);
      if (header.length < 64 || String.fromCharCodes(header.sublist(0, 15)) != 'SQLite format 3') return null;
      return (header[60] << 24) | (header[61] << 16) | (header[62] << 8) | header[63];
    } finally {
      raf.closeSync();
    }
  }

  /// Before the database is opened: copies it when its schema is older than
  /// [schemaVersion] (the app was updated and will migrate it). Returns the
  /// copy, or null when nothing needed saving.
  File? beforeMigration(int schemaVersion) {
    final version = _versionOf(databaseFile, password);
    if (version == null || version == 0 || version >= schemaVersion) return null;
    return _copyClosed('before-v$schemaVersion');
  }

  /// A consistent copy of the open [db] in [folder] (`VACUUM INTO`), then old
  /// automatic copies pruned.
  Future<File> snapshot(ExpenseDatabase db, String reason) async {
    final target = _newFile(folder, reason);
    await _vacuumInto(db, target);
    _prune();
    return target;
  }

  /// A copy of the open [db] in [directory], chosen by the user; never pruned.
  Future<File> saveTo(ExpenseDatabase db, Directory directory) async {
    final target = _newFile(directory, 'manual');
    await _vacuumInto(db, target);
    return target;
  }

  /// Automatic copies, newest first.
  List<BackupFile> list() {
    if (!folder.existsSync()) return const [];
    return [
      for (final f in folder.listSync().whereType<File>())
        if (_name.firstMatch(f.uri.pathSegments.last) case final m?)
          BackupFile(
            f,
            DateTime(
              int.parse(m[1]!),
              int.parse(m[2]!),
              int.parse(m[3]!),
              int.parse(m[4]!),
              int.parse(m[5]!),
              int.parse(m[6]!),
            ),
            m[7]!,
          ),
    ]..sort((a, b) => b.file.path.compareTo(a.file.path));
  }

  /// Checks [backup] and stages it: it replaces the database at the next start
  /// (the open database can't be swapped under the running app). Throws
  /// [RestoreException] for a file that isn't a backup of this app or comes
  /// from a newer version (with a newer schema than [schemaVersion]).
  ///
  /// An encrypted copy opens with the current [password], else with
  /// [filePassword] (the password when the copy was made), else throws
  /// [RestoreProblem.wrongPassword]. The staged file is encrypted with the
  /// current password whatever it was: a plaintext copy from before
  /// encryption, or a copy made with an older password.
  void stageRestore(File backup, int schemaVersion, {String? filePassword}) {
    final state = databaseFileState(backup);
    if (state == DatabaseFileState.missing) throw const RestoreException(RestoreProblem.notADatabase);
    String? opensWith;
    if (state == DatabaseFileState.encrypted) {
      opensWith = [password, filePassword].whereType<String>().where((p) => passwordOpens(backup, p)).firstOrNull;
      if (opensWith == null) {
        throw RestoreException(password == null ? RestoreProblem.notADatabase : RestoreProblem.wrongPassword);
      }
    }
    final version = _versionOf(backup, opensWith);
    if (version == null) throw const RestoreException(RestoreProblem.notADatabase);
    if (version > schemaVersion) throw const RestoreException(RestoreProblem.newerVersion);
    final check = opensWith == null
        ? sqlite3.open(backup.path, mode: OpenMode.readOnly)
        : openKeyed(backup, opensWith, readOnly: true);
    try {
      final tables = {
        for (final r in check.select("SELECT name FROM sqlite_master WHERE type = 'table'")) r['name'] as String,
      };
      if (!tables.containsAll(['transactions', 'statements', 'accounts', 'categories'])) {
        throw const RestoreException(RestoreProblem.notExpenses);
      }
      if (tables.contains(devCopyTable)) throw const RestoreException(RestoreProblem.devCopy);
    } on SqliteException {
      throw const RestoreException(RestoreProblem.notADatabase);
    } finally {
      check.close();
    }
    backup.copySync(_pending.path);
    final wal = File('${backup.path}-wal');
    if (wal.existsSync()) wal.copySync('${_pending.path}-wal');
    // Both fold the copied WAL into the staged file (only the file is moved at the next start).
    final current = password;
    if (current == null) return;
    if (opensWith == null) {
      encryptInPlace(_pending, current);
    } else {
      rekeyFile(_pending, opensWith, current);
    }
  }

  /// At start, once the owner typed [newPassword], before the database is
  /// opened ([openEncryptedDatabase]): checks the password on an encrypted
  /// database (throws [WrongPasswordException]), encrypts a plaintext one
  /// (from before encryption) and the plaintext copies, then copies the
  /// database when [schemaVersion] will migrate it ([beforeMigration]).
  /// Sets [password]. Slow on purpose (key derivation): run it off the UI
  /// thread.
  PrepareResult prepare(String newPassword, int schemaVersion) {
    final state = databaseFileState(databaseFile);
    if (state == DatabaseFileState.encrypted && !passwordOpens(databaseFile, newPassword)) {
      throw const WrongPasswordException();
    }
    if (state != DatabaseFileState.encrypted && passwordProblem(newPassword) != null) {
      throw ArgumentError('password too short');
    }
    final converted = state == DatabaseFileState.plaintext;
    if (converted) encryptInPlace(databaseFile, newPassword);
    password = newPassword;
    final copies = encryptPlaintextCopies();
    final migrationCopy = beforeMigration(schemaVersion);
    return PrepareResult(converted: converted, copiesEncrypted: copies, migrationCopy: migrationCopy);
  }

  /// Changes the password of the open [db], and of a restore staged for the
  /// next start (so it opens with the new one). Copies already made keep the
  /// password they were made with.
  Future<void> changePassword(ExpenseDatabase db, String newPassword) async {
    final old = password;
    await changeDatabasePassword(db, newPassword);
    if (old != null && databaseFileState(_pending) == DatabaseFileState.encrypted) {
      rekeyFile(_pending, old, newPassword);
    }
    password = newPassword;
  }

  /// Encrypts with [password] every plaintext file the app keeps: the
  /// automatic copies and a staged restore (left by a version without
  /// encryption). Returns how many were encrypted. Their old bytes may stay
  /// on the disk until overwritten: full-disk encryption covers that.
  int encryptPlaintextCopies() {
    final current = password;
    if (current == null) return 0;
    var count = 0;
    for (final f in [for (final b in list()) b.file, _pending]) {
      if (databaseFileState(f) != DatabaseFileState.plaintext) continue;
      encryptInPlace(f, current);
      count++;
    }
    return count;
  }

  /// Schema version of [file]: from the header for a plaintext file, opened
  /// with [password] for an encrypted one (null if it doesn't open).
  static int? _versionOf(File file, String? password) => switch (databaseFileState(file)) {
    DatabaseFileState.missing => null,
    DatabaseFileState.plaintext => schemaVersionOf(file),
    DatabaseFileState.encrypted when password != null => _tryVersion(file, password),
    DatabaseFileState.encrypted => null,
  };

  static int? _tryVersion(File file, String password) {
    try {
      return schemaVersionWith(file, password);
    } on WrongPasswordException {
      return null;
    }
  }

  bool get hasPendingRestore => _pending.existsSync();

  /// At start, before the database is opened: replaces it with a staged
  /// restore, keeping a copy of the replaced one. Returns whether a restore
  /// was applied. Waits a little for the previous app instance to let go of
  /// the file.
  Future<bool> applyPendingRestore() async {
    if (!_pending.existsSync()) return false;
    for (var attempt = 0; ; attempt++) {
      try {
        if (databaseFile.existsSync()) _copyClosed('before-restore');
        for (final suffix in const ['-wal', '-shm', '-journal']) {
          final f = File('${databaseFile.path}$suffix');
          if (f.existsSync()) f.deleteSync();
        }
        _pending.copySync(databaseFile.path);
        _pending.deleteSync();
        return true;
      } on FileSystemException {
        if (attempt >= 20) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
  }

  /// Makes [source], a closed encrypted database elsewhere (a USB key, a
  /// downloaded copy, the file from another computer), the database at
  /// [databaseFile]: copied, never moved, with its WAL. The database it
  /// replaces, if any, is kept first as a copy (`before-replace`). Nothing is
  /// opened: the password stays [source]'s.
  void adopt(File source) {
    if (databaseFileState(source) != DatabaseFileState.encrypted) {
      throw ArgumentError.value(source.path, 'source', 'not an encrypted database');
    }
    if (databaseFile.existsSync()) _copyClosed('before-replace');
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final f = File('${databaseFile.path}$suffix');
      if (f.existsSync()) f.deleteSync();
    }
    databaseFile.parent.createSync(recursive: true);
    source.copySync(databaseFile.path);
    final wal = File('${source.path}-wal');
    if (wal.existsSync()) wal.copySync('${databaseFile.path}-wal');
  }

  File _copyClosed(String reason) {
    final target = _newFile(folder, reason);
    databaseFile.copySync(target.path);
    final wal = File('${databaseFile.path}-wal');
    if (wal.existsSync()) wal.copySync('${target.path}-wal');
    _prune();
    return target;
  }

  File _newFile(Directory directory, String reason) {
    directory.createSync(recursive: true);
    final t = _now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp = '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
    var file = File('${directory.path}${Platform.pathSeparator}expenses-$stamp-$reason.sqlite');
    for (var n = 2; file.existsSync(); n++) {
      file = File('${directory.path}${Platform.pathSeparator}expenses-$stamp-$n-$reason.sqlite');
    }
    return file;
  }

  Future<void> _vacuumInto(ExpenseDatabase db, File target) =>
      db.customStatement("VACUUM INTO '${target.path.replaceAll("'", "''")}'");

  void _prune() {
    for (final old in list().skip(keep)) {
      old.file.deleteSync();
      final wal = File('${old.file.path}-wal');
      if (wal.existsSync()) wal.deleteSync();
    }
  }
}
