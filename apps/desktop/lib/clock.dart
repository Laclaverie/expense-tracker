import 'dart:io';

/// The clock behind [appNow]: [clockFromEnvironment] of the process; tests
/// assign a fixed one.
DateTime Function() appClock = clockFromEnvironment(Platform.environment);

/// "Now" for everything the app shows (current month, targets, due
/// statements). A demo (`demo.bat`) fixes it to the day its made-up data ends.
DateTime appNow() => appClock();

/// `EXPENSES_TODAY=YYYY-MM-DD`, read only together with `EXPENSES_DB_DIR` (a
/// scratch or demo database, like `EXPENSES_DB_PASSWORD`): that day at noon,
/// fixed. Otherwise, or for a day that doesn't exist, the real clock.
DateTime Function() clockFromEnvironment(Map<String, String> env) {
  final day = env['EXPENSES_DB_DIR'] == null ? null : env['EXPENSES_TODAY'];
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(day ?? '');
  if (m == null) return DateTime.now;
  final (y, mo, d) = (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  final fixed = DateTime(y, mo, d, 12);
  if (fixed.year != y || fixed.month != mo || fixed.day != d) return DateTime.now;
  return () => fixed;
}
