// Database encryption (B11): the database and every copy the app makes are
// unreadable without the password; nothing readable is left behind on disk;
// a database moves to another computer (or system) with its password only.
import 'dart:convert';
import 'dart:io';

import 'package:banks/desjardins.dart';
import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:pdf_words/pdf_words.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

const fixtures = '../banks/test/fixtures/desjardins';
const password = 'correct horse battery staple';
const other = 'another long password 2026';

ImportedStatement load(String name) => toImported(
  parseStatement(
    DocumentWords.fromJson(jsonDecode(File('$fixtures/$name').readAsStringSync()) as Map<String, dynamic>),
  ),
);

/// Texts that must never appear in an encrypted file: the schema and the
/// descriptions of the card fixture's lines.
final secrets = () {
  final s = load('desjardins-card-2026-09.synthetic.json');
  return {
    'SQLite format 3',
    'CREATE TABLE',
    'transactions',
    for (final l in s.lines)
      if (l.description.length >= 8) l.description,
  };
}();

/// The secrets found in [file] and its journal files (none expected).
List<String> leaks(File file) {
  final found = <String>[];
  for (final suffix in const ['', '-wal', '-shm', '-journal']) {
    final f = File('${file.path}$suffix');
    if (!f.existsSync()) continue;
    final text = latin1.decode(f.readAsBytesSync());
    for (final s in secrets) {
      if (text.contains(s)) found.add('${f.uri.pathSegments.last}: $s');
    }
  }
  return found;
}

void main() {
  late Directory dir;
  late File file;
  var now = DateTime(2026, 10, 31, 9);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('expenses-crypt');
    file = File('${dir.path}/expenses.sqlite');
    now = DateTime(2026, 10, 31, 9);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Backups backups({String? pw = password}) => Backups(file, password: pw, clock: () => now);

  /// A plaintext database (the app before encryption) with the card fixture.
  Future<int> createPlaintext(File f) async {
    final db = ExpenseDatabase(NativeDatabase(f));
    try {
      await ImportService(db)
          .importStatement(load('desjardins-card-2026-09.synthetic.json'), fileHash: 'h', fileName: 'n');
      return (await db.select(db.transactions).get()).length;
    } finally {
      await db.close();
    }
  }

  /// An encrypted database with the card fixture; returns its line count.
  Future<int> createEncrypted(File f, [String pw = password]) async {
    final db = openEncryptedDatabase(f, pw);
    try {
      await ImportService(db)
          .importStatement(load('desjardins-card-2026-09.synthetic.json'), fileHash: 'h', fileName: 'n');
      return (await db.select(db.transactions).get()).length;
    } finally {
      await db.close();
    }
  }

  Future<int> countWith(File f, String pw) async {
    final db = openEncryptedDatabase(f, pw);
    try {
      return (await db.select(db.transactions).get()).length;
    } finally {
      await db.close();
    }
  }

  group('password rules', () {
    test('more than 16 characters, counted as typed', () {
      expect(passwordProblem('a' * 16), PasswordProblem.tooShort);
      expect(passwordProblem('a' * 17), isNull);
      expect(passwordProblem('é' * 16), PasswordProblem.tooShort, reason: 'an accented letter is one character');
      expect(passwordProblem('é' * 17), isNull);
      expect(passwordProblem('🔒' * 16), PasswordProblem.tooShort, reason: 'an emoji is one character');
      expect(passwordProblem(''), PasswordProblem.tooShort);
    });

    test('typed twice: both entries must match', () {
      expect(passwordProblem(password, password), isNull);
      expect(passwordProblem(password, '$password '), PasswordProblem.mismatch);
      expect(passwordProblem('short', 'short'), PasswordProblem.tooShort, reason: 'length checked first');
    });
  });

  group('the database file', () {
    test('a new database is encrypted: no schema, no line text readable', () async {
      final count = await createEncrypted(file);
      expect(count, greaterThan(10));
      expect(databaseFileState(file), DatabaseFileState.encrypted);
      expect(leaks(file), isEmpty);
    });

    test('unreadable without the password by any SQLite tool', () async {
      await createEncrypted(file);
      final raw = sqlite3.open(file.path);
      addTearDown(raw.close);
      expect(
        () => raw.select('SELECT count(*) FROM transactions'),
        throwsA(isA<SqliteException>().having((e) => e.message, 'message', contains('not a database'))),
      );
    });

    test('a wrong password does not open it; the right one does, with all data', () async {
      final count = await createEncrypted(file);
      expect(passwordOpens(file, other), isFalse);
      expect(passwordOpens(file, '${password}x'), isFalse);
      expect(passwordOpens(file, password.toUpperCase()), isFalse, reason: 'case matters');
      expect(passwordOpens(file, password), isTrue);
      expect(await countWith(file, password), count);
      expect(() => openKeyed(file, other), throwsA(isA<WrongPasswordException>()));
    });

    test('opens with the plain SQLCipher 4 settings (DB Browser for SQLite, sqlcipher shell)', () async {
      await createEncrypted(file);
      final raw = sqlite3.open(file.path, mode: OpenMode.readOnly);
      addTearDown(raw.close);
      // What a SQLCipher tool does: SQLCipher 4 defaults, then the key.
      raw.execute("PRAGMA cipher = 'sqlcipher'");
      raw.execute('PRAGMA legacy = 4');
      raw.execute("PRAGMA kdf_iter = 256000");
      raw.execute("PRAGMA key = '$password'");
      expect(raw.select('SELECT count(*) AS c FROM transactions').first['c'], greaterThan(10));
    });

    test('quotes, semicolons and accents in the password are kept as typed', () async {
      const tricky = "l'été \"dernier\"; DROP TABLE x; -- ok";
      final count = await createEncrypted(file, tricky);
      expect(passwordOpens(file, tricky), isTrue);
      expect(passwordOpens(file, "l'ete \"dernier\"; DROP TABLE x; -- ok"), isFalse);
      expect(await countWith(file, tricky), count);
    });

    test('journal files of an open database are encrypted too', () async {
      final db = openEncryptedDatabase(file, password);
      addTearDown(db.close);
      await db.customStatement('PRAGMA journal_mode = WAL');
      await ImportService(db)
          .importStatement(load('desjardins-card-2026-09.synthetic.json'), fileHash: 'h', fileName: 'n');
      expect(File('${file.path}-wal').existsSync(), isTrue);
      expect(leaks(file), isEmpty);
    });

    test('changing the password: the old one stops working, data kept', () async {
      final count = await createEncrypted(file);
      final db = openEncryptedDatabase(file, password);
      await changeDatabasePassword(db, other);
      expect((await db.select(db.transactions).get()).length, count, reason: 'still open and usable');
      await db.close();
      expect(passwordOpens(file, password), isFalse);
      expect(await countWith(file, other), count);
      expect(leaks(file), isEmpty);
    });

    test('a new password must be long enough', () async {
      await createEncrypted(file);
      final db = openEncryptedDatabase(file, password);
      addTearDown(db.close);
      expect(() => changeDatabasePassword(db, 'too short'), throwsArgumentError);
      await db.close();
      expect(passwordOpens(file, password), isTrue);
    });
  });

  group('first start with this version', () {
    test('a plaintext database is encrypted in place, nothing lost, WAL folded in', () async {
      final count = await createPlaintext(file);
      final raw = sqlite3.open(file.path)..execute('PRAGMA journal_mode = WAL');
      raw.execute(
        "INSERT INTO categories (id, name_fr, name_en, type, color, sort_order) "
        "VALUES ('test.in_wal', 'M', 'M', 'expense', 0, 0)",
      );
      raw.close();
      expect(databaseFileState(file), DatabaseFileState.plaintext);

      final result = backups(pw: null).prepare(password, ExpenseDatabase.currentSchemaVersion);
      expect(result.converted, isTrue);
      expect(databaseFileState(file), DatabaseFileState.encrypted);
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        expect(File('${file.path}$suffix').existsSync(), isFalse, reason: suffix);
      }
      expect(leaks(file), isEmpty);
      expect(await countWith(file, password), count);
      final db = openKeyed(file, password);
      addTearDown(db.close);
      expect(db.select("SELECT id FROM categories WHERE id = 'test.in_wal'"), hasLength(1));
    });

    test('plaintext automatic copies and a staged restore are encrypted too', () async {
      await createPlaintext(file);
      final plain = Backups(file, clock: () => now);
      final db = ExpenseDatabase(NativeDatabase(file));
      final copies = [await plain.snapshot(db, 'before-import'), await plain.snapshot(db, 'before-categories')];
      plain.stageRestore(copies.first, ExpenseDatabase.currentSchemaVersion);
      await db.close();
      expect(copies.map(databaseFileState), everyElement(DatabaseFileState.plaintext));

      final result = backups(pw: null).prepare(password, ExpenseDatabase.currentSchemaVersion);
      expect(result.copiesEncrypted, 3, reason: 'two copies + the staged restore');
      for (final f in [...copies, File('${file.path}.restore')]) {
        expect(databaseFileState(f), DatabaseFileState.encrypted, reason: f.path);
        expect(leaks(f), isEmpty, reason: f.path);
        expect(passwordOpens(f, password), isTrue, reason: f.path);
      }
    });

    test('a new database needs a long password; nothing created before it', () {
      expect(() => backups(pw: null).prepare('short', ExpenseDatabase.currentSchemaVersion), throwsArgumentError);
      expect(file.existsSync(), isFalse);
      final result = backups(pw: null).prepare(password, ExpenseDatabase.currentSchemaVersion);
      expect((result.converted, result.copiesEncrypted, result.migrationCopy), (false, 0, null));
    });

    test('a wrong password changes nothing on disk', () async {
      await createEncrypted(file);
      final before = file.readAsBytesSync();
      final b = backups(pw: null);
      expect(() => b.prepare(other, ExpenseDatabase.currentSchemaVersion), throwsA(isA<WrongPasswordException>()));
      expect(b.password, isNull);
      expect(file.readAsBytesSync(), before);
      expect(Directory('${dir.path}/backups').existsSync(), isFalse);
    });

    test('an app update copies the encrypted database before migrating it', () async {
      await createEncrypted(file);
      final version = schemaVersionWith(file, password)!;
      expect(version, ExpenseDatabase.currentSchemaVersion);
      expect(backups().prepare(password, version).migrationCopy, isNull);
      final copy = backups().prepare(password, version + 1).migrationCopy!;
      expect(copy.path, endsWith('before-v${version + 1}.sqlite'));
      expect(leaks(copy), isEmpty);
      expect(passwordOpens(copy, password), isTrue);
    });
  });

  group('copies', () {
    test('automatic and manual copies are encrypted with the same password', () async {
      final count = await createEncrypted(file);
      final db = openEncryptedDatabase(file, password);
      final auto = await backups().snapshot(db, 'before-import');
      final usb = Directory('${dir.path}/usb')..createSync();
      final manual = await backups().saveTo(db, usb);
      await db.close();
      for (final f in [auto, manual]) {
        expect(databaseFileState(f), DatabaseFileState.encrypted);
        expect(leaks(f), isEmpty);
        expect(passwordOpens(f, other), isFalse);
        expect(await countWith(f, password), count);
      }
    });

    test('restore: a copy with the current password', () async {
      final count = await createEncrypted(file);
      final db = openEncryptedDatabase(file, password);
      final copy = await backups().snapshot(db, 'before-import');
      await db.customStatement('DELETE FROM transactions');
      await db.close();
      backups().stageRestore(copy, ExpenseDatabase.currentSchemaVersion);
      expect(leaks(File('${file.path}.restore')), isEmpty);
      expect(await backups().applyPendingRestore(), isTrue);
      expect(await countWith(file, password), count);
    });

    test('restore: a copy made with an older password asks for it, then takes the current one', () async {
      final count = await createEncrypted(file, other);
      final old = File('${dir.path}/old-copy.sqlite');
      file.copySync(old.path);
      file.deleteSync();
      await createEncrypted(file); // the database now, with the current password
      final b = backups();
      expect(
        () => b.stageRestore(old, ExpenseDatabase.currentSchemaVersion),
        throwsA(isA<RestoreException>().having((e) => e.problem, 'problem', RestoreProblem.wrongPassword)),
      );
      expect(
        () => b.stageRestore(old, ExpenseDatabase.currentSchemaVersion, filePassword: 'not the right one at all'),
        throwsA(isA<RestoreException>().having((e) => e.problem, 'problem', RestoreProblem.wrongPassword)),
      );
      expect(b.hasPendingRestore, isFalse);
      b.stageRestore(old, ExpenseDatabase.currentSchemaVersion, filePassword: other);
      final staged = File('${file.path}.restore');
      expect(passwordOpens(staged, password), isTrue, reason: 'staged with the current password');
      expect(passwordOpens(staged, other), isFalse);
      expect(passwordOpens(old, other), isTrue, reason: 'the chosen file itself is left as it was');
      await b.applyPendingRestore();
      expect(await countWith(file, password), count);
    });

    test('restore: a plaintext copy from before encryption is staged encrypted', () async {
      final plainCopy = File('${dir.path}/before-encryption.sqlite');
      final count = await createPlaintext(plainCopy);
      backups().stageRestore(plainCopy, ExpenseDatabase.currentSchemaVersion);
      final staged = File('${file.path}.restore');
      expect(databaseFileState(staged), DatabaseFileState.encrypted);
      expect(leaks(staged), isEmpty);
      await backups().applyPendingRestore();
      expect(await countWith(file, password), count);
    });

    test('restore refuses files that are not this app\'s database', () async {
      final b = backups();
      Matcher problem(RestoreProblem p) => throwsA(isA<RestoreException>().having((e) => e.problem, 'problem', p));
      final empty = File('${dir.path}/empty.sqlite')..writeAsBytesSync([]);
      expect(() => b.stageRestore(empty, 99), problem(RestoreProblem.notADatabase));
      final text = File('${dir.path}/notes.txt')..writeAsStringSync('hello, not a database');
      expect(() => b.stageRestore(text, 99), problem(RestoreProblem.wrongPassword), reason: 'looks encrypted');
      final foreign = File('${dir.path}/foreign.sqlite');
      openKeyed(foreign, password)
        ..execute('CREATE TABLE other (x)')
        ..close();
      expect(() => b.stageRestore(foreign, 99), problem(RestoreProblem.notExpenses));
      final newer = File('${dir.path}/newer.sqlite');
      await createEncrypted(newer);
      expect(
        () => b.stageRestore(newer, ExpenseDatabase.currentSchemaVersion - 1),
        problem(RestoreProblem.newerVersion),
      );
      expect(b.hasPendingRestore, isFalse);
    });

    test('changing the password re-keys a staged restore; older copies keep their password', () async {
      await createEncrypted(file);
      final b = backups();
      final db = openEncryptedDatabase(file, password);
      final copy = await b.snapshot(db, 'before-import');
      b.stageRestore(copy, ExpenseDatabase.currentSchemaVersion);
      await b.changePassword(db, other);
      await db.close();
      expect(b.password, other);
      expect(passwordOpens(File('${file.path}.restore'), other), isTrue);
      expect(passwordOpens(copy, password), isTrue, reason: 'a copy made before keeps its password');
      await b.applyPendingRestore();
      expect(passwordOpens(file, other), isTrue);
    });
  });

  test('moving to a new computer: one file and its password, nothing re-imported', () async {
    // Old computer: the database, then a manual copy to a USB key.
    final count = await createEncrypted(file);
    final oldDb = openEncryptedDatabase(file, password);
    await oldDb.customStatement(
      "INSERT INTO rules (category_id, merchant_key, created_at) VALUES ('food.coffee', 'ACME CAFE', '2026-10-31T09:00:00')",
    );
    final usb = Directory('${dir.path}/usb')..createSync();
    final copy = await backups().saveTo(oldDb, usb);
    await oldDb.close();

    // New computer: first start creates an empty database with a new password.
    final newFile = File('${dir.path}/new-computer/expenses.sqlite')..parent.createSync();
    final fresh = Backups(newFile, clock: () => now)..prepare(other, ExpenseDatabase.currentSchemaVersion);
    await openEncryptedDatabase(newFile, other).close();
    // Restore the copy (made with the old password), then restart.
    fresh.stageRestore(copy, ExpenseDatabase.currentSchemaVersion, filePassword: password);
    final restart = Backups(newFile, clock: () => now);
    await restart.applyPendingRestore();
    restart.prepare(other, ExpenseDatabase.currentSchemaVersion);

    final db = openEncryptedDatabase(newFile, other);
    addTearDown(db.close);
    expect((await db.select(db.transactions).get()).length, count);
    expect((await db.select(db.rules).get()).single.merchantKey, 'ACME CAFE');
    expect(leaks(newFile), isEmpty);
  });
}
