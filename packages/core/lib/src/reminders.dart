/// When the next statement of each type should be available, to remind the
/// user to download it from their bank.
library;

/// The next statement of [format] (bank [institution]) should be out: the
/// latest imported one ends on [lastEnd], the next on about [expectedEnd].
class DueStatement {
  const DueStatement(this.institution, this.format, this.lastEnd, this.expectedEnd);

  final String institution;
  final String format;
  final DateTime lastEnd;
  final DateTime expectedEnd;
}

/// End of the statement after one ending on [end]: one month later, a month
/// end staying a month end (Sep 30 -> Oct 31), other days clamped (Jan 31 is a
/// month end; Jan 30 -> Feb 28).
DateTime nextStatementEnd(DateTime end) {
  final lastDay = DateTime.utc(end.year, end.month + 1, 0).day;
  final nextLastDay = DateTime.utc(end.year, end.month + 2, 0).day;
  final day = end.day == lastDay ? nextLastDay : (end.day > nextLastDay ? nextLastDay : end.day);
  return DateTime.utc(end.year, end.month + 1, day);
}

/// Statement types whose next statement should be available on [today]:
/// [graceDays] after it ends (banks publish a few days later). One entry per
/// (institution, format), from the end dates of the imported [statements].
List<DueStatement> dueStatements(
  Iterable<(String institution, String format, DateTime end)> statements,
  DateTime today, {
  int graceDays = 3,
}) {
  final latest = <(String, String), DateTime>{};
  for (final (institution, format, end) in statements) {
    final key = (institution, format);
    if (latest[key] == null || end.isAfter(latest[key]!)) latest[key] = end;
  }
  final day = DateTime.utc(today.year, today.month, today.day);
  return [
    for (final MapEntry(key: (institution, format), value: end) in latest.entries)
      if (day.isAfter(nextStatementEnd(end).add(Duration(days: graceDays))))
        DueStatement(institution, format, end, nextStatementEnd(end)),
  ]..sort((a, b) => a.expectedEnd.compareTo(b.expectedEnd));
}
