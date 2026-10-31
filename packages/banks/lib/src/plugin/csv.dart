/// Small CSV helpers shared by plug-ins reading a bank's text export. Each bank
/// still describes its own columns: exports are not normalized between banks.
library;

/// Fields of one CSV [line] split on [separator]. Double quotes group a field
/// (`"a,b"`), `""` inside quotes is one quote; quotes are removed.
List<String> splitCsvLine(String line, {String separator = ','}) {
  final fields = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quoted) {
      if (c != '"') {
        field.write(c);
      } else if (i + 1 < line.length && line[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = false;
      }
    } else if (c == '"') {
      quoted = true;
    } else if (line.startsWith(separator, i)) {
      fields.add(field.toString());
      field.clear();
      i += separator.length - 1;
    } else {
      field.write(c);
    }
  }
  return fields..add(field.toString());
}

/// The separator (`,` `;` tab `|`) splitting [lines] into the most columns
/// with the same count on most lines; `,` when none splits them.
String guessCsvSeparator(List<String> lines) {
  var best = ',';
  var bestScore = 0;
  for (final sep in const [',', ';', '\t', '|']) {
    final counts = <int, int>{};
    for (final l in lines.take(200)) {
      final n = splitCsvLine(l, separator: sep).length;
      if (n > 1) counts.update(n, (v) => v + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) continue;
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    final score = top.value * 1000 + top.key;
    if (score > bestScore) (best, bestScore) = (sep, score);
  }
  return best;
}

final _amount = RegExp(r'^(-)?\(?\$?(-)?(\d{1,3}(?:[  ,.]\d{3})+|\d+)[.,](\d{2})\$?\)?(-)?$');

/// Cents of an amount field with two decimals: `1234.56`, `1 234,56`,
/// `1,234.56`, `-12.30`, `12.30-`, `(12.30)`, `$12.30`. Null when [text] isn't
/// one (empty, integer, text).
int? parseCsvCents(String text) {
  final t = text.trim();
  final m = _amount.firstMatch(t);
  if (m == null) return null;
  final cents = int.parse(m[3]!.replaceAll(RegExp(r'[  ,.]'), '')) * 100 + int.parse(m[4]!);
  final negative = m[1] != null || m[2] != null || m[5] != null || (t.startsWith('(') && t.endsWith(')'));
  return negative ? -cents : cents;
}

/// A date written `YYYY/MM/DD`, `YYYY-MM-DD` (year first) or `DD/MM/YYYY`,
/// `MM/DD/YYYY` (year last, [dayFirst] picks which), as UTC midnight. Null
/// when [text] isn't a valid date.
DateTime? parseCsvDate(String text, {bool dayFirst = true}) {
  final m = RegExp(r'^(\d{1,4})[/.-](\d{1,2})[/.-](\d{1,4})$').firstMatch(text.trim());
  if (m == null) return null;
  final a = int.parse(m[1]!), b = int.parse(m[2]!), c = int.parse(m[3]!);
  final (y, mo, d) = m[1]!.length == 4
      ? (a, b, c)
      : (m[3]!.length == 4 ? (c, dayFirst ? b : a, dayFirst ? a : b) : (0, 0, 0));
  if (y == 0 || mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  final date = DateTime.utc(y, mo, d);
  return date.month == mo ? date : null;
}
