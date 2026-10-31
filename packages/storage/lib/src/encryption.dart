import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database.dart';

/// Database encryption (B11, doc 08 decision log): the whole file is
/// encrypted (SQLite3MultipleCiphers in SQLCipher 4 mode, selected in the
/// workspace `pubspec.yaml`), with a key derived from the owner's password
/// by SQLCipher itself (PBKDF2-HMAC-SHA512, 256 000 rounds). No key is
/// stored anywhere: no Windows or Linux key store, no file next to the
/// database. The same password opens the file on any system, and in DB
/// Browser for SQLite (SQLCipher) or the `sqlcipher` shell. Forgotten
/// password = data lost.
///
/// Every copy the app makes (automatic backups, manual copies, the WAL file)
/// is encrypted with the same key: `VACUUM INTO` keeps the cipher.

/// Passwords are deliberately long: more than 16 characters.
const minPasswordLength = 17;

enum PasswordProblem {
  /// [minPasswordLength] characters at least.
  tooShort,

  /// The two entries differ.
  mismatch,
}

/// Why [password] (typed twice when [confirmation] is given) can't be used,
/// or null. Length counts characters as typed (an accented letter is one).
PasswordProblem? passwordProblem(String password, [String? confirmation]) {
  if (password.runes.length < minPasswordLength) return PasswordProblem.tooShort;
  if (confirmation != null && confirmation != password) return PasswordProblem.mismatch;
  return null;
}

/// What a database file on disk is, read from its first bytes (no key needed).
enum DatabaseFileState {
  /// No file (or an empty one): a new database will be created.
  missing,

  /// Readable by anyone: a database from before encryption, to convert.
  plaintext,

  /// Not readable without its password.
  encrypted,
}

DatabaseFileState databaseFileState(File file) {
  if (!file.existsSync() || file.lengthSync() == 0) return DatabaseFileState.missing;
  final raf = file.openSync();
  try {
    final header = raf.readSync(16);
    return String.fromCharCodes(header.take(15)) == 'SQLite format 3'
        ? DatabaseFileState.plaintext
        : DatabaseFileState.encrypted;
  } finally {
    raf.closeSync();
  }
}

String _quoted(String s) => "'${s.replaceAll("'", "''")}'";

/// Cipher scheme then key, on a connection just opened (before any read).
void _cipher(Database db) {
  db.execute("PRAGMA cipher = 'sqlcipher'");
  db.execute('PRAGMA legacy = 4');
}

/// Sets [password] as the key of [db], just opened. Throws
/// [WrongPasswordException] when the file doesn't open with it.
void applyKey(Database db, String password) {
  _cipher(db);
  db.execute('PRAGMA key = ${_quoted(password)}');
  try {
    db.select('SELECT count(*) FROM sqlite_master');
  } on SqliteException {
    throw const WrongPasswordException();
  }
}

/// The password doesn't open the file (or the file isn't a database).
class WrongPasswordException implements Exception {
  const WrongPasswordException();

  @override
  String toString() => 'WrongPasswordException';
}

/// Opens [file] with [password] (raw connection, for checks and copies).
/// Throws [WrongPasswordException].
Database openKeyed(File file, String password, {bool readOnly = false}) {
  final db = sqlite3.open(file.path, mode: readOnly ? OpenMode.readOnly : OpenMode.readWriteCreate);
  try {
    applyKey(db, password);
    return db;
  } catch (_) {
    db.close();
    rethrow;
  }
}

/// Whether [password] opens [file].
bool passwordOpens(File file, String password) {
  try {
    openKeyed(file, password, readOnly: true).close();
    return true;
  } on WrongPasswordException {
    return false;
  }
}

/// The app's database in [file], encrypted with [password]; created when
/// missing. Check the password first ([passwordOpens]): a wrong one fails
/// on the first query, in the background isolate.
ExpenseDatabase openEncryptedDatabase(File file, String password) =>
    ExpenseDatabase(NativeDatabase.createInBackground(file, setup: _setupWith(password)));

/// A top-level function so the closure only captures the password (sent to
/// the background isolate).
void Function(Database) _setupWith(String password) =>
    (db) => applyKey(db, password);

/// Encrypts a plaintext database [file] in place with [password] (its WAL
/// checkpointed first, journal files removed). Does nothing to a file
/// already encrypted.
void encryptInPlace(File file, String password) {
  if (databaseFileState(file) != DatabaseFileState.plaintext) return;
  final db = sqlite3.open(file.path);
  try {
    // Encryption can't start in WAL mode: fold the WAL into the file first.
    db.execute('PRAGMA journal_mode = DELETE');
    _cipher(db);
    db.execute('PRAGMA rekey = ${_quoted(password)}');
  } finally {
    db.close();
  }
  for (final suffix in const ['-wal', '-shm', '-journal']) {
    final f = File('${file.path}$suffix');
    if (f.existsSync()) f.deleteSync();
  }
}

/// Re-encrypts [file] from [oldPassword] to [newPassword] (closed file: a
/// backup or a staged restore). Throws [WrongPasswordException].
void rekeyFile(File file, String oldPassword, String newPassword) {
  final db = openKeyed(file, oldPassword);
  try {
    db.execute('PRAGMA journal_mode = DELETE');
    db.execute('PRAGMA rekey = ${_quoted(newPassword)}');
  } finally {
    db.close();
  }
}

/// Changes the password of the open [db] (the app's database). Copies made
/// before keep the password they were made with.
Future<void> changeDatabasePassword(ExpenseDatabase db, String newPassword) async {
  final problem = passwordProblem(newPassword);
  if (problem != null) throw ArgumentError(problem.name);
  // drift keeps one connection: rekey rewrites every page in one go.
  final mode = (await db.customSelect('PRAGMA journal_mode').getSingle()).data.values.first as String;
  await db.customStatement('PRAGMA journal_mode = DELETE');
  await db.customStatement('PRAGMA rekey = ${_quoted(newPassword)}');
  await db.customStatement('PRAGMA journal_mode = $mode');
}

/// The schema version (`PRAGMA user_version`) of [file] opened with
/// [password]; null when it's missing. Throws [WrongPasswordException].
int? schemaVersionWith(File file, String password) {
  if (databaseFileState(file) == DatabaseFileState.missing) return null;
  final db = openKeyed(file, password, readOnly: true);
  try {
    return db.select('PRAGMA user_version').first.values.first as int;
  } finally {
    db.close();
  }
}
