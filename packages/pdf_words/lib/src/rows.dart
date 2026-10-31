import 'words.dart';

/// Words sharing the same baseline.
class Row {
  Row(this.words);

  final List<Word> words;

  double get y => words.first.y;

  List<String> get texts => [for (final w in words) w.text];

  String get text => texts.join(' ');

  /// Words whose left edge is in `[from, to)`.
  List<Word> between(double from, double to) => [
    for (final w in words)
      if (w.x0 >= from && w.x0 < to) w,
  ];

  @override
  String toString() => '${y.toStringAsFixed(1)} ${words.join(' ')}';
}

/// Groups [words] into rows: same baseline within [tolerance] points.
///
/// Rows are sorted top to bottom, words in a row left to right. Numbers split
/// by a space thousands separator (`2` `835,60`) are merged into one word.
List<Row> groupRows(List<Word> words, {double tolerance = 2.5}) {
  final sorted = [...words]..sort((a, b) => a.y.compareTo(b.y));
  final rows = <List<Word>>[];
  for (final w in sorted) {
    if (rows.isNotEmpty && (w.y - rows.last.first.y).abs() < tolerance) {
      rows.last.add(w);
    } else {
      rows.add([w]);
    }
  }
  return [for (final r in rows) Row(mergeThousands(r..sort((a, b) => a.x0.compareTo(b.x0))))];
}

final _group = RegExp(r'^\d{1,3}$');
final _rest = RegExp(r'^\d{3}[.,]\d{2}');

/// Merges `2` + `098.68` into `2098.68` when the words are adjacent.
List<Word> mergeThousands(List<Word> words) {
  final out = <Word>[];
  for (final w in words) {
    if (out.isNotEmpty && _group.hasMatch(out.last.text) && _rest.hasMatch(w.text) && w.x0 - out.last.x1 < 6) {
      final prev = out.removeLast();
      out.add(Word(prev.text + w.text, prev.x0, w.x1, w.y));
    } else {
      out.add(w);
    }
  }
  return out;
}
