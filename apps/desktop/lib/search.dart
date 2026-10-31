/// Global search (Ctrl+K): which transactions a typed query finds.
///
/// Each word must match: an amount (`42,50`, `42.50`, `42 $`: that exact
/// amount; `42`: from 42,00 to 42,99, or the text `42`), a date (`2026-10`,
/// `2026-10-12`, `12/10`, `12/10/2026`, day first) or text found in the
/// merchant, description, note, place or account name, accents and case
/// ignored.
library;

class SearchQuery {
  SearchQuery._(this._words);

  factory SearchQuery.parse(String text) => SearchQuery._([
    for (final w in text.trim().split(RegExp(r'\s+')))
      if (w.isNotEmpty && w != r'$' && w != '€') _Word.parse(w),
  ]);

  final List<_Word> _words;

  bool get isEmpty => _words.isEmpty;

  /// [text]: the searchable texts of one transaction (merchant, description,
  /// note, place, account); [cents]: its amount, any sign.
  bool matches({required List<String?> text, required int cents, required DateTime date}) {
    if (_words.isEmpty) return false;
    final haystack = foldText(text.whereType<String>().join(' '));
    return _words.every((w) => w.matches(haystack, cents.abs(), date));
  }
}

class _Word {
  _Word(this.text, {this.cents, this.whole, this.datePrefix, this.day, this.month, this.year});

  factory _Word.parse(String raw) {
    final w = raw.replaceAll(RegExp(r'[$€]'), '');
    final text = foldText(raw);
    final amount = RegExp(r'^-?(\d+)(?:[.,](\d{1,2}))?$').firstMatch(w);
    if (amount != null) {
      final units = int.parse(amount[1]!);
      final decimals = amount[2];
      if (decimals != null) return _Word(text, cents: units * 100 + int.parse(decimals.padRight(2, '0')));
      return _Word(text, whole: units);
    }
    if (RegExp(r'^\d{4}-\d{2}(-\d{2})?$').hasMatch(w)) return _Word(text, datePrefix: w);
    final dm = RegExp(r'^(\d{1,2})/(\d{1,2})(?:/(\d{4}))?$').firstMatch(w);
    if (dm != null) {
      return _Word(
        text,
        day: int.parse(dm[1]!),
        month: int.parse(dm[2]!),
        year: dm[3] == null ? null : int.parse(dm[3]!),
      );
    }
    return _Word(text);
  }

  final String text;
  final int? cents;
  final int? whole;
  final String? datePrefix;
  final int? day, month, year;

  bool matches(String haystack, int amount, DateTime date) {
    if (cents != null) return amount == cents;
    if (whole != null) return amount ~/ 100 == whole || haystack.contains(text);
    if (datePrefix != null) return _iso(date).startsWith(datePrefix!);
    if (day != null) return date.day == day && date.month == month && (year == null || date.year == year);
    return haystack.contains(text);
  }
}

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'î': 'i', 'ï': 'i', 'í': 'i', 'ô': 'o', 'ö': 'o', 'ó': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u', //
  'ÿ': 'y', 'œ': 'oe', 'æ': 'ae',
};

/// Lower case without accents: `Épicerie` → `epicerie`.
String foldText(String s) {
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final r in lower.runes) {
    final c = String.fromCharCode(r);
    out.write(_accents[c] ?? c);
  }
  return out.toString();
}
