/// A word on a PDF page.
///
/// Coordinates are in PDF points. [x0] and [x1] are the left and right edges,
/// [y] is the text baseline measured from the top of the page.
class Word {
  const Word(this.text, this.x0, this.x1, this.y);

  factory Word.fromJson(List<dynamic> json) =>
      Word(json[0] as String, (json[1] as num).toDouble(), (json[2] as num).toDouble(), (json[3] as num).toDouble());

  final String text;
  final double x0;
  final double x1;
  final double y;

  Word withText(String text) => Word(text, x0, x1, y);

  /// Compact form: `[text, x0, x1, y]`, coordinates rounded to 0.1 pt.
  List<Object> toJson() => [text, _r(x0), _r(x1), _r(y)];

  static double _r(double v) => (v * 10).roundToDouble() / 10;

  @override
  String toString() => '$text@${x0.round()}';
}

/// The words of one page, in reading order (top to bottom, left to right).
class PageWords {
  const PageWords(this.width, this.height, this.words);

  factory PageWords.fromJson(Map<String, dynamic> json) => PageWords(
    (json['width'] as num).toDouble(),
    (json['height'] as num).toDouble(),
    [for (final w in json['words'] as List) Word.fromJson(w as List)],
  );

  final double width;
  final double height;
  final List<Word> words;

  Map<String, Object> toJson() => {
    'width': width,
    'height': height,
    'words': [for (final w in words) w.toJson()],
  };
}

/// All pages of a document.
class DocumentWords {
  const DocumentWords(this.pages);

  factory DocumentWords.fromJson(Map<String, dynamic> json) =>
      DocumentWords([for (final p in json['pages'] as List) PageWords.fromJson(p as Map<String, dynamic>)]);

  final List<PageWords> pages;

  Map<String, Object> toJson() => {
    'pages': [for (final p in pages) p.toJson()],
  };
}
