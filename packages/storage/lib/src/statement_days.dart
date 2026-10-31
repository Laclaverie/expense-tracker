import 'package:core/core.dart';

import 'database.dart';

/// Days each of [rows] covers, by statement id: its period, or for a
/// statement printing only its closing date (`coversSincePrevious`) the days
/// since the previous one of its format and file type ([cardRanges]).
Map<int, DayRange> statementDays(Iterable<Statement> rows) {
  final out = <int, DayRange>{};
  final chained = <(String, String), List<Statement>>{};
  for (final s in rows) {
    if (s.coversSincePrevious) {
      chained.putIfAbsent((s.format, s.fileType), () => []).add(s);
    } else {
      out[s.id] = (s.periodStart, s.periodEnd);
    }
  }
  for (final list in chained.values) {
    list.sort((a, b) => a.periodEnd.compareTo(b.periodEnd));
    final ranges = cardRanges(list.map((s) => s.periodEnd));
    for (final (i, s) in list.indexed) {
      out[s.id] = ranges[i];
    }
  }
  return out;
}

bool insideDays(DateTime day, Iterable<DayRange> ranges) =>
    ranges.any((r) => !day.isBefore(r.$1) && !day.isAfter(r.$2));
