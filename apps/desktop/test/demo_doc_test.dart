import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'demo/stops.dart';

/// The README images and the walkthrough follow the same stops.
void main() {
  test('docs/13-demo.md names every demo stop', () {
    final doc = File('../../docs/13-demo.md').readAsStringSync();
    for (final stop in demoStops) {
      expect(doc, contains('`${stop.id}`'), reason: stop.id);
    }
  });
}
