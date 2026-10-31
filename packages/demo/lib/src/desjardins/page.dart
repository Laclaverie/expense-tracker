import 'package:pdf_words/pdf_words.dart';

/// Writes words where a PDF would put them: x from the left, y = baseline,
/// widths from a simple font model (capitals and digits wider than lowercase).
class PageBuilder {
  PageBuilder({this.size = 8});

  /// Font size of the next words.
  double size;
  final List<Word> words = [];

  double _char(String c) {
    if (RegExp(r'[A-ZÀ-Ý0-9#&@%]').hasMatch(c)) return .67 * size;
    if (RegExp(r'[a-zà-ÿ]').hasMatch(c)) return .53 * size;
    return .3 * size;
  }

  double width(String word) => word.split('').fold(0.0, (s, c) => s + _char(c));
  double get space => .32 * size;

  /// [text] from [x]; returns where it ends.
  double text(String text, double x, double y) {
    for (final w in text.split(' ')) {
      if (w.isEmpty) continue;
      final end = x + width(w);
      words.add(Word(w, x, end, y));
      x = end + space;
    }
    return x - space;
  }

  /// [text] ending at [x1].
  void right(String text, double x1, double y) {
    final total = text.split(' ').where((w) => w.isNotEmpty).fold(0.0, (s, w) => s + width(w) + space) - space;
    this.text(text, x1 - total, y);
  }

  PageWords build() => PageWords(612, 792, words);
}

/// `1234,56` (card) or `1234.56` (account); [credit] adds `CR`, [negative] a trailing `-`.
String money(int cents, {String decimal = ',', bool credit = false}) {
  final a = cents.abs();
  final s = '${a ~/ 100}$decimal${(a % 100).toString().padLeft(2, '0')}';
  return credit ? '${s}CR' : (cents < 0 && decimal == '.' ? '$s-' : s);
}

String two(int n) => n.toString().padLeft(2, '0');

const frenchMonths = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin', //
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
const frenchMonthCodes = ['JAN', 'FEV', 'MAR', 'AVR', 'MAI', 'JUN', 'JUL', 'AOU', 'SEP', 'OCT', 'NOV', 'DEC'];

/// Splits [text] into rows of at most [maxWidth] points.
List<String> wrap(PageBuilder page, String text, double maxWidth) {
  final rows = <String>[];
  var current = '';
  for (final w in text.split(' ')) {
    final next = current.isEmpty ? w : '$current $w';
    if (current.isNotEmpty && page.width(next) > maxWidth) {
      rows.add(current);
      current = w;
    } else {
      current = next;
    }
  }
  if (current.isNotEmpty) rows.add(current);
  return rows;
}
