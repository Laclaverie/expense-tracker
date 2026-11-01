import 'package:expense_desktop/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool isNow(DateTime t) => DateTime.now().difference(t).inSeconds.abs() < 2;

  test('a demo folder with EXPENSES_TODAY fixes the day, at noon', () {
    final clock = clockFromEnvironment({'EXPENSES_DB_DIR': r'C:\demo', 'EXPENSES_TODAY': '2026-10-22'});
    expect(clock(), DateTime(2026, 10, 22, 12));
  });

  test('without EXPENSES_DB_DIR the real clock', () {
    expect(isNow(clockFromEnvironment({'EXPENSES_TODAY': '2026-10-22'})()), isTrue);
  });

  test('a malformed day falls back to the real clock', () {
    for (final day in ['2026-13-01', 'hier', '2026-02-30', '']) {
      final clock = clockFromEnvironment({'EXPENSES_DB_DIR': r'C:\demo', 'EXPENSES_TODAY': day});
      expect(isNow(clock()), isTrue, reason: day);
    }
  });
}
