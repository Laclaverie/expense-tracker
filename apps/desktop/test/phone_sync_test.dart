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

  /// The current session's copy (each session has its own file).
  File copyOf(PhoneSync sync) => sync.copy!;

  /// Every session copy in the scratch folder.
  List<File> copies() => scratch.existsSync()
      ? scratch.listSync().whereType<File>().where((f) => f.uri.pathSegments.last.startsWith('phone-copy')).toList()
      : const [];

  test('the copy offered to the phone is encrypted with the database password', () async {
    final sync = make();
    addTearDown(sync.dispose);
    await sync.pair();
    await sync.send();
    expect(sync.serving, isTrue);
    expect(databaseFileState(copyOf(sync)), DatabaseFileState.encrypted);
    expect(passwordOpens(copyOf(sync), 'pw-test correct horse battery'), isTrue);
    await sync.stop();
    expect(copies(), isEmpty);
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
    expect(copies(), isEmpty);
    // Nothing listens on the default port range any more.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(sync.error, isNull);
  });

  test('leftover copies are deleted when a PhoneSync is created', () {
    scratch.createSync(recursive: true);
    for (final name in ['phone-copy.sqlite', 'phone-copy-3.sqlite', 'phone-copy-3.sqlite-wal']) {
      File('${scratch.path}/$name').writeAsStringSync('left by a crash');
    }
    final sync = make();
    addTearDown(sync.dispose);
    expect(copies(), isEmpty);
  });

  test('a send right after a stop keeps its own copy while the stopped one cleans up', () async {
    final sync = make();
    addTearDown(sync.dispose);
    await sync.pair();
    final first = sync.send();
    await sync.stop();
    await sync.send();
    await first;
    expect(sync.serving, isTrue);
    expect(sync.error, isNull);
    expect(copyOf(sync).existsSync(), isTrue, reason: 'the stopped session must not delete the new copy');
    expect(copies().map((f) => f.path), [copyOf(sync).path]);
    await sync.stop();
    expect(copies(), isEmpty);
  });

  test('the window running out deletes the copy', () async {
    final sync = make(window: const Duration(milliseconds: 300));
    addTearDown(sync.dispose);
    await sync.pair();
    await sync.send();
    expect(copyOf(sync).existsSync(), isTrue);
    for (var i = 0; sync.serving && i < 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(sync.serving, isFalse);
    expect(sync.syncedAt, isNull);
    expect(copies(), isEmpty);
  });
}
