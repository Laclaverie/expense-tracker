/// Amount and date helpers for Desjardins statement text.
library;

/// Account statement amount: `1753.48`, negative with trailing minus `0.01-`.
final dotAmount = RegExp(r'^\d+\.\d{2}-?$');

/// Card statement amount: `2948,64`, credit with `CR` suffix `2799,20CR`.
final commaAmount = RegExp(r'^\d+,\d{2}(CR)?$');

/// Parses an amount word into cents. Accepts dot or comma decimals, a trailing
/// `-` (negative) and a `CR` suffix (ignored here: callers decide the sign).
int parseCents(String text) {
  final negative = text.endsWith('-');
  final t = text.replaceAll('-', '').replaceAll('CR', '').replaceAll(',', '.');
  final dot = t.indexOf('.');
  final cents = int.parse(t.substring(0, dot)) * 100 + int.parse(t.substring(dot + 1));
  return negative ? -cents : cents;
}

/// Dates on statement lines have no year. The line belongs to the statement
/// period ending on [periodEnd]: a month later than the period's month means
/// the previous year (December lines on a January statement).
DateTime inferDate(int day, int month, DateTime periodEnd) {
  final year = month > periodEnd.month ? periodEnd.year - 1 : periodEnd.year;
  return DateTime.utc(year, month, day);
}

/// Formats cents as `1 234,56` for messages.
String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final units = (abs ~/ 100).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ' ');
  return '$sign$units,${(abs % 100).toString().padLeft(2, '0')}';
}
