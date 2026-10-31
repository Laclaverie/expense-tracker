import 'package:banks/plugin.dart';

import 'model.dart';
import 'text.dart';

/// Parses a Desjardins account statement ("Relevé de compte").
///
/// Layout: a header with the period (`du 1er mai au 31 mai 2026`), then one
/// section per account, each a table `Date Code Description Frais Retrait
/// Dépôt Solde` starting with a `Solde reporté` row. Amounts are right-aligned
/// under their column header. Long descriptions wrap onto a second row, which
/// can carry the line's amounts.
AccountStatement parseAccountStatement(DocumentWords doc) {
  final pages = [for (final p in doc.pages) groupRows(p.words)];
  final (start, end) = _period(pages.first);
  final sections = <AccountSection>[];
  AccountSection? section;
  String? pendingId, pendingName;
  Map<String, double>? columns; // header word -> right edge
  AccountLine? last;
  var descriptionX = 0.0; // where the last line's description starts
  var lastY = 0.0; // baseline of the last line's latest row

  outer:
  for (final rows in pages) {
    last = null; // a line never continues on the next page
    for (final row in rows) {
      final t = row.texts;
      if (t.first == 'SOMMAIRE') break outer; // fee summary after the last section
      if (t.contains('Retrait') && t.contains('Solde') && t.first == 'Date') {
        columns = {for (final w in row.words.skip(3)) w.text: w.x1};
        continue;
      }
      if (row.words.first.x0 < 52 && RegExp(r'^[A-Z]{2,4}$').hasMatch(t.first) && !_isLine(row)) {
        // Section header: `EOP COMPTE POUR PROFESSIONNELS`, `ET 1 Compte d'épargne`.
        final numbered = t.length > 1 && RegExp(r'^\d+$').hasMatch(t[1]);
        pendingId = numbered ? '${t[0]} ${t[1]}' : t[0];
        pendingName = t.skip(numbered ? 2 : 1).join(' ');
        continue;
      }
      if (t.length >= 2 && t[0] == 'Solde' && t[1] == 'reporté' && pendingId != null) {
        final amounts = row.words.where((w) => dotAmount.hasMatch(w.text));
        section = AccountSection(
          id: pendingId,
          name: pendingName!,
          opening: amounts.isEmpty ? 0 : parseCents(amounts.last.text),
        );
        sections.add(section);
        pendingId = null;
        last = null;
        continue;
      }
      if (section == null || columns == null) continue;
      if (_isLine(row)) {
        final codeWord = row.words[2];
        last = AccountLine(
          date: inferDate(int.parse(t[0]), frenchMonthAbbreviations[t[1]]!, end),
          code: codeWord.text,
          description: _description(row, codeWord.x1, columns),
        );
        section.lines.add(last);
        descriptionX = row.words.length > 3 ? row.words[3].x0 : codeWord.x1;
        lastY = row.y;
        _assignAmounts(last, row, columns);
      } else if (last != null && (row.words.first.x0 - descriptionX).abs() < 5 && row.y - lastY < 16) {
        // Wrapped description (aligned with the description), possibly carrying the amounts.
        final more = _description(row, 0, columns);
        if (more.isNotEmpty) last.description = '${last.description} $more';
        lastY = row.y;
        _assignAmounts(last, row, columns);
      } else {
        last = null; // anything else ends the line (e.g. TFSA rate details)
      }
    }
  }
  return AccountStatement(periodStart: start, periodEnd: end, sections: sections);
}

bool _isLine(Row row) {
  final t = row.texts;
  return t.length >= 3 &&
      row.words.first.x0 < 70 &&
      RegExp(r'^\d{1,2}$').hasMatch(t[0]) &&
      frenchMonthAbbreviations.containsKey(t[1]);
}

double _firstColumn(Map<String, double> columns) => columns.values.reduce((a, b) => a < b ? a : b) - 30;

String _description(Row row, double after, Map<String, double> columns) =>
    row.words.where((w) => w.x0 > after && w.x0 < _firstColumn(columns) - 10).map((w) => w.text).join(' ');

void _assignAmounts(AccountLine line, Row row, Map<String, double> columns) {
  for (final w in row.words) {
    if (!dotAmount.hasMatch(w.text) || w.x0 < _firstColumn(columns) - 10) continue;
    final column = columns.entries.reduce((a, b) => (a.value - w.x1).abs() <= (b.value - w.x1).abs() ? a : b).key;
    final cents = parseCents(w.text);
    switch (column) {
      case 'Frais':
        line.fee = cents;
      case 'Retrait':
        line.withdrawal = cents;
      case 'Solde':
        line.balance = cents;
      default: // Dépôt
        line.deposit = cents;
    }
  }
}

final _periodPattern = RegExp(r'du (\d{1,2})(?:er)? (\S+)(?: (\d{4}))? au (\d{1,2})(?:er)? (\S+) (\d{4})');

(DateTime, DateTime) _period(List<Row> firstPage) {
  for (final row in firstPage) {
    final m = _periodPattern.firstMatch(row.text);
    if (m == null) continue;
    final endYear = int.parse(m[6]!);
    final endMonth = frenchMonthNames[m[5]!.toLowerCase()]!;
    final startMonth = frenchMonthNames[m[2]!.toLowerCase()]!;
    final startYear = m[3] != null ? int.parse(m[3]!) : (startMonth > endMonth ? endYear - 1 : endYear);
    return (DateTime.utc(startYear, startMonth, int.parse(m[1]!)), DateTime.utc(endYear, endMonth, int.parse(m[4]!)));
  }
  throw const FormatException('Statement period ("du … au …") not found');
}
