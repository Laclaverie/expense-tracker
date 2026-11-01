import 'dart:io';

import 'package:demo/demo.dart';
import 'package:test/test.dart';

/// The bank plug-ins' fixtures are written by `dart run demo:fixtures`: a
/// change to the couple's life or a writer must show up here before it
/// silently changes what the bank tests read.
void main() {
  test('fixtures are up to date', () {
    final files = Directory('../banks/test/fixtures/desjardins')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.synthetic.json'))
        .toList();
    expect(files, isNotEmpty);
    final byName = {for (final s in desjardinsStatements(liveHousehold())) s.name: s};
    for (final f in files) {
      final name = f.uri.pathSegments.last.replaceFirst('.synthetic.json', '');
      expect(byName, contains(name));
      expect(fixtureJson(byName[name]!), f.readAsStringSync(), reason: name);
    }
  });
}
