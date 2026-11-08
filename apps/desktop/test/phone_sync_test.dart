// PhoneSync sessions: stopping while preparing, encrypted copy, cleanup of leftovers and of timed-out copies.
import 'dart:io';

import 'package:expense_desktop/phone_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

void main() {
  late Directory dir;
  late File dbFile;
  late ExpenseDatabase db;
  late Directory scratch;

  setUp(() async {
    HttpOverrides.global = null;
    dir = Directory.systemTemp.createTempSync('expenses-phone-sync');
    dbFile = File('${dir.path}/expenses.sqlite');
    scratch = Directory('${dir.path}/sync');
    Backups(dbFile).prepare('pw-test correct horse battery', ExpenseDatabase.currentSchemaVersion);
    db = openEncryptedDatabase(dbFile, 'pw-test correct horse battery');
    await db.select(db.categories).get();
  });
  tearDown(() async {
    await db.close();
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // Still held for a moment on Windows.
    }
  });

  PhoneSync make({Duration window = const Duration(minutes: 10)}) => PhoneSync(
    db,
    scratch,
    bindAddress: InternetAddress.loopbackIPv4,
    discoveryPort: 0,
    window: window,
    hosts: () async => ['127.0.0.1'],
  );

  File copyOf() => File('${scratch.path}/phone-copy.sqlite');

  test('the copy offered to the phone is encrypted with the database password', () async {
    final sync = make();
    addTearDown(sync.dispose);
    await sync.pair();
    await sync.send();
    expect(sync.serving, isTrue);
    expect(databaseFileState(copyOf()), DatabaseFileState.encrypted);
    expect(passwordOpens(copyOf(), 'pw-test correct horse battery'), isTrue);
    await sync.stop();
    expect(copyOf().existsSync(), isFalse);
  });

  test('stop while the copy is being prepared starts no server and leaves no copy', () async {
    final sync = make();
    addTearDown(sync.dispose);
    await sync.pair();
    final sending = sync.send();
    await sync.stop();
    await sending;
    expect(sync.serving, isFalse);
    expect(sync.port, isNull);
    expect(copyOf().existsSync(), isFalse);
    // Nothing listens on the default port range any more.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(sync.error, isNull);
  });

  test('a leftover copy is deleted when a PhoneSync is created', () {
    scratch.createSync(recursive: true);
    copyOf().writeAsStringSync('left by a crash');
    final sync = make();
    addTearDown(sync.dispose);
    expect(copyOf().existsSync(), isFalse);
  });

  test('the window running out deletes the copy', () async {
    final sync = make(window: const Duration(milliseconds: 300));
    addTearDown(sync.dispose);
    await sync.pair();
    await sync.send();
    expect(copyOf().existsSync(), isTrue);
    for (var i = 0; sync.serving && i < 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(sync.serving, isFalse);
    expect(sync.syncedAt, isNull);
    expect(copyOf().existsSync(), isFalse);
  });
}
