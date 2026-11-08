// The phone app is read only: nothing in lib/ may call a repository or import-service write method.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ never references a write method', () {
    const writes = [
      'setCategory',
      'addManual',
      'delete',
      'confirm',
      'saveTarget',
      'addRule',
      'rename',
      'archive',
      'refreshAutomaticCategories',
      'importStatement',
    ];
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.contains('l10n')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        for (final w in writes) {
          // A call: `archived` (a column) or `deleteSync(` on a file of the app folder are not database writes.
          if (RegExp(r'\b' + w + r'\s*\(').hasMatch(code)) offenders.add('${file.path}:${i + 1}: $w');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
