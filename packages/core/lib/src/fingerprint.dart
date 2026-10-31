import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'merchant.dart';

/// Identifies a statement line so re-importing the same (or an overlapping)
/// statement doesn't create duplicates.
///
/// [occurrence] distinguishes identical lines on the same day (two coffees
/// at the same bar): 0 for the first, 1 for the second…
String lineFingerprint({
  required String institution,
  required String accountRef,
  required DateTime date,
  required int amount,
  required String description,
  required int occurrence,
}) {
  final normalized = stripAccents(description).replaceAll(RegExp(r'\s+'), ' ').trim();
  final input = [
    institution,
    accountRef,
    date.toIso8601String().substring(0, 10),
    amount,
    normalized,
    occurrence,
  ].join('|');
  return sha1.convert(utf8.encode(input)).toString();
}

/// Assigns occurrence indexes: lines with the same account, date, amount and
/// description get 0, 1, 2… in order.
List<int> occurrences(Iterable<(String, DateTime, int, String)> lines) {
  final seen = <(String, DateTime, int, String), int>{};
  return [for (final l in lines) seen.update(l, (n) => n + 1, ifAbsent: () => 0)];
}
