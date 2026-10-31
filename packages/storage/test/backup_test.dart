// Automatic and manual copies of the database, restore staged then applied at
// the next start.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late File file;
  var now = DateTime(2026, 10, 25, 9, 30);
  Backups backups({int keep = 15}) => Backups(file, keep: keep, clock: () => now);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('expenses-backup');
    file = File('${dir.path}/expenses.sqlite');
    now = DateTime(2026, 10, 25, 9, 30);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// A current-schema database with one category added by the test.
  Future<void> create({String marker = 'test.marker'}) async {
    final db = ExpenseDatabase(NativeDatabase(file));
    try {
      await db.customStatement(
        'INSERT INTO categories (id, name_fr, name_en, type, color, sort_order) '
        "VALUES ('$marker', 'M', 'M', 'expense', 0, 0)",
      );
    } finally {
      await db.close();
    }
  }

  Future<bool> hasMarker(File f, String marker) async {
    final db = ExpenseDatabase(NativeDatabase(f));
    addTearDown(db.close);
    final rows = await db.customSelect("SELECT id FROM categories WHERE id = '$marker'").get();
    return rows.isNotEmpty;
  }

  test('schema version read from the header; null for other files', () async {
    await create();
    expect(Backups.schemaVersionOf(file), ExpenseDatabase(NativeDatabase.memory()).schemaVersion);
    final text = File('${dir.path}/x.txt')..writeAsStringSync('hello');
    expect(Backups.schemaVersionOf(text), isNull);
    expect(Backups.schemaVersionOf(File('${dir.path}/missing')), isNull);
  });

  test('copy before a migration only when the file is older', () async {
    await create();
    final version = Backups.schemaVersionOf(file)!;
    expect(backups().beforeMigration(version), isNull, reason: 'same version: nothing to migrate');
    final copy = backups().beforeMigration(version + 1)!;
    expect(copy.path, endsWith('expenses-20261025-093000-before-v${version + 1}.sqlite'));
    expect(await hasMarker(copy, 'test.marker'), isTrue);
    expect(Backups(File('${dir.path}/none.sqlite')).beforeMigration(99), isNull, reason: 'first start');
  });

  test('snapshot of the open database; only the newest automatic copies kept', () async {
    await create();
    final db = ExpenseDatabase(NativeDatabase(file));
    addTearDown(db.close);
    for (var i = 0; i < 4; i++) {
      now = now.add(const Duration(minutes: 1));
      await backups(keep: 3).snapshot(db, 'before-import');
    }
    final list = backups().list();
    expect(list.map((b) => b.date.minute), [34, 33, 32]);
    expect(list.first.reason, 'before-import');
    expect(await hasMarker(list.first.file, 'test.marker'), isTrue);

    final manual = Directory('${dir.path}/usb');
    final saved = await backups(keep: 1).saveTo(db, manual);
    expect(saved.parent.path, manual.path);
    expect(backups().list(), hasLength(3), reason: 'manual copies are not pruned nor listed');
  });

  test('restore: refuses other files, applies a staged backup and keeps the replaced database', () async {
    await create(marker: 'old.marker');
    final db = ExpenseDatabase(NativeDatabase(file));
    final old = await backups().snapshot(db, 'before-import');
    await db.customStatement("DELETE FROM categories WHERE id = 'old.marker'");
    await db.close();
    final version = Backups.schemaVersionOf(file)!;

    final text = File('${dir.path}/x.sqlite')..writeAsStringSync('hello');
    expect(
      () => backups().stageRestore(text, version),
      throwsA(isA<RestoreException>().having((e) => e.problem, 'problem', RestoreProblem.notADatabase)),
    );
    expect(
      () => backups().stageRestore(old, version - 1),
      throwsA(isA<RestoreException>().having((e) => e.problem, 'problem', RestoreProblem.newerVersion)),
    );
    final other = File('${dir.path}/other.sqlite');
    sqlite3.open(other.path)
      ..execute('CREATE TABLE notes (text TEXT); PRAGMA user_version = 1;')
      ..close();
    expect(
      () => backups().stageRestore(other, version),
      throwsA(isA<RestoreException>().having((e) => e.problem, 'problem', RestoreProblem.notExpenses)),
    );
    expect(backups().hasPendingRestore, isFalse);

    backups().stageRestore(old, version);
    expect(backups().hasPendingRestore, isTrue);
    now = now.add(const Duration(minutes: 5));
    expect(await backups().applyPendingRestore(), isTrue);
    expect(backups().hasPendingRestore, isFalse);
    expect(await hasMarker(file, 'old.marker'), isTrue);
    final replaced = backups().list().firstWhere((b) => b.reason == 'before-restore');
    expect(await hasMarker(replaced.file, 'old.marker'), isFalse, reason: 'the database as it was before');
    expect(await backups().applyPendingRestore(), isFalse);
  });

  test('adopt: another encrypted file becomes the database, the replaced one is kept', () async {
    const pw = 'adopted file password';
    final other = File('${dir.path}/usb/expenses.sqlite')..parent.createSync();
    final db = openEncryptedDatabase(other, pw);
    await db.customStatement(
      'INSERT INTO categories (id, name_fr, name_en, type, color, sort_order) '
      "VALUES ('other.marker', 'M', 'M', 'expense', 0, 0)",
    );
    await db.close();

    final plain = File('${dir.path}/plain.sqlite');
    sqlite3.open(plain.path).close();
    expect(() => backups().adopt(plain), throwsArgumentError, reason: 'only encrypted databases');

    await create(marker: 'old.marker'); // the database being replaced (plaintext in this test)
    backups().adopt(other);
    expect(passwordOpens(file, pw), isTrue, reason: 'same password as the adopted file');
    expect(other.existsSync(), isTrue, reason: 'copied, never moved');
    final kept = backups().list().singleWhere((b) => b.reason == 'before-replace');
    expect(await hasMarker(kept.file, 'old.marker'), isTrue);

    file.deleteSync();
    backups().adopt(other); // nothing to replace: a new computer
    expect(passwordOpens(file, pw), isTrue);
  });
}
