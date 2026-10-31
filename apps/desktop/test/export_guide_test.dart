import 'dart:io';

import 'package:banks/banks.dart' show banks;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every export guide screenshot is in the app assets, declared in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final b in banks) {
      final guide = b.exportGuide;
      if (guide == null) continue;
      expect(guide.stepsFr, hasLength(guide.stepsEn.length), reason: '${b.institution}: same steps in both languages');
      for (final MapEntry(key: step, value: image) in guide.images.entries) {
        expect(step, inInclusiveRange(1, guide.stepsEn.length), reason: '${b.institution}: image of step $step');
        expect(File('assets/guides/${b.institution}/$image').existsSync(), isTrue, reason: image);
      }
      if (guide.images.isNotEmpty) expect(pubspec, contains('- assets/guides/${b.institution}/'));
    }
  });
}
