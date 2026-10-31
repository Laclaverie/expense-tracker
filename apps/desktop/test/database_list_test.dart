// Files the password screen offers: the app's own one always, others most
// recent first, kept as paths only.
import 'dart:io';

import 'package:expense_desktop/database_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('expenses-list'));
  tearDown(() => dir.deleteSync(recursive: true));

  File other(String name) => File(p.join(dir.path, 'elsewhere', '$name.sqlite'))..createSync(recursive: true);

  test('a first start lists the app\'s own file only', () {
    final list = DatabaseList.load(dir);
    expect(list.files.map((f) => f.path), [p.join(dir.path, 'expenses.sqlite')]);
    expect(list.last.path, list.home.path, reason: 'offered even before it exists');
    expect(list.isHome(list.home), isTrue);
  });

  test('the last file unlocked comes first, and is offered at the next start', () {
    final list = DatabaseList.load(dir);
    final copy = other('dev-copy');
    list.use(copy);
    expect(list.files.first.path, copy.path);
    final again = DatabaseList.load(dir);
    expect(again.last.path, copy.path);
    expect(again.files.length, 2);
    again.home.createSync();
    again.use(again.home);
    expect(DatabaseList.load(dir).last.path, again.home.path);
  });

  test('the same file is listed once, whatever the case of its path', () {
    final list = DatabaseList.load(dir);
    final copy = other('shared');
    list.use(copy);
    list.use(File(copy.path.toUpperCase()));
    expect(list.files.length, 2);
  }, skip: !Platform.isWindows);

  test('a file gone (a key not plugged in) is skipped at start but stays listed', () {
    final list = DatabaseList.load(dir);
    final copy = other('on-a-key');
    list.use(copy);
    copy.deleteSync();
    final again = DatabaseList.load(dir);
    expect(again.last.path, again.home.path);
    expect(again.files.map((f) => f.path), contains(copy.path));
  });

  test('forgetting removes the entry, never the app\'s own file nor any file', () {
    final list = DatabaseList.load(dir);
    final copy = other('old');
    list.use(copy);
    list.forget(copy);
    list.forget(list.home);
    expect(DatabaseList.load(dir).files.map((f) => f.path), [list.home.path]);
    expect(copy.existsSync(), isTrue);
  });

  test('at most ${DatabaseList.max} files: the oldest others go first', () {
    final list = DatabaseList.load(dir);
    for (var i = 0; i < 12; i++) {
      list.use(other('copy$i'));
    }
    final names = [for (final f in DatabaseList.load(dir).files) p.basename(f.path)];
    expect(names.length, DatabaseList.max);
    expect(names.first, 'copy11.sqlite');
    expect(names, contains('expenses.sqlite'));
    expect(names, isNot(contains('copy0.sqlite')));
  });

  test('a damaged list starts again from the app\'s own file', () {
    File(p.join(dir.path, 'databases.json')).writeAsStringSync('{not json');
    expect(DatabaseList.load(dir).files.length, 1);
    File(p.join(dir.path, 'databases.json')).writeAsStringSync('{"recent": [3]}');
    expect(DatabaseList.load(dir).files.length, 1);
  });
}
