/// Learns categories from the user's own categorized lines: a naive Bayes
/// classifier over the words of the description, their 3-letter chunks (so cut
/// or glued words still match: `HIGHLAN`, `DDVESCHOPSTICKSRE`) and the city.
///
/// There is no saved model: it is rebuilt from the reviewed transactions
/// (a few thousand lines take milliseconds), so corrections, merged or retired
/// categories and new ones apply at once. It only suggests (one-click choices
/// in the review queue), it never sets a category: measured on real data, its
/// guess for a never-seen merchant was right only about a third of the time,
/// the right category in its top 3 about half the time.
library;

import 'dart:math' as math;

import 'merchant.dart';

/// One guess: the category, its probability among the known categories, and
/// the word behind it (`SUSHI`) with how many reviewed lines of that category
/// contain it.
class ClassifierGuess {
  const ClassifierGuess(this.categoryId, this.probability, this.word, this.support);

  final String categoryId;
  final double probability;
  final String word;
  final int support;

  @override
  String toString() => '$categoryId ${(probability * 100).round()}% ($word ×$support)';
}

/// The words of a line: description words (no store numbers) and its city,
/// uppercase without accents. `SQ *HOJO'S SUSHI #12`, `CHARLOTTETOWN PE` ->
/// `SQ`, `HOJO'S`, `SUSHI`, `@CHARLOTTETOWN`.
List<String> classifierWords(String description, String? location) {
  final words = <String>[];
  for (final w in stripAccents(description).split(RegExp(r"[^A-Z0-9'&-]+"))) {
    if (w.length >= 2 && !RegExp(r'\d').hasMatch(w)) words.add(w);
  }
  final place = location == null ? <String>[] : stripAccents(location).split(RegExp(r'\s+'));
  // The last word is the province or country code: the city comes before it.
  for (final w in place.length > 1 ? place.sublist(0, place.length - 1) : place) {
    if (w.length >= 3 && !RegExp(r'\d').hasMatch(w)) words.add('@$w');
  }
  return words;
}

/// Features of a line: its words and the 3-letter chunks of description words.
Set<String> _features(List<String> words) => {
  for (final w in words) ...[
    w,
    if (!w.startsWith('@') && w.length > 3)
      for (var i = 0; i + 3 <= w.length; i++) '#${w.substring(i, i + 3)}',
  ],
};

class CategoryClassifier {
  CategoryClassifier();

  /// Builds a classifier from `(description, location, categoryId)` lines.
  factory CategoryClassifier.train(Iterable<(String, String?, String)> lines) {
    final c = CategoryClassifier();
    for (final (description, location, category) in lines) {
      c.add(description, location, category);
    }
    return c;
  }

  final _docs = <String, int>{};
  final _counts = <String, Map<String, int>>{};
  final _totals = <String, int>{};
  final _vocabulary = <String>{};
  var _lineCount = 0;

  int get lineCount => _lineCount;

  /// Learns one categorized line.
  void add(String description, String? location, String categoryId) {
    final features = _features(classifierWords(description, location));
    if (features.isEmpty) return;
    _lineCount++;
    _docs[categoryId] = (_docs[categoryId] ?? 0) + 1;
    final counts = _counts.putIfAbsent(categoryId, () => {});
    for (final f in features) {
      counts[f] = (counts[f] ?? 0) + 1;
      _vocabulary.add(f);
    }
    _totals[categoryId] = (_totals[categoryId] ?? 0) + features.length;
  }

  /// The most likely categories for a line, best first, at most [limit]. Empty
  /// when no word of its description was ever seen in a reviewed line (only
  /// the city or 3-letter chunks in common is too weak: a town says little
  /// about what was bought), or when nothing was learned yet.
  List<ClassifierGuess> suggest(String description, String? location, {int limit = 3}) {
    final words = classifierWords(description, location);
    final features = _features(words).where(_vocabulary.contains).toSet();
    final name = [
      for (final w in words)
        if (!w.startsWith('@')) w,
    ];
    if (!name.any(_vocabulary.contains)) return const [];
    final v = _vocabulary.length;
    final scores = <String, double>{};
    for (final c in _docs.keys) {
      final counts = _counts[c]!;
      final denominator = math.log(_totals[c]! + v);
      var score = math.log(_docs[c]! / _lineCount);
      for (final f in features) {
        score += math.log((counts[f] ?? 0) + 1) - denominator;
      }
      scores[c] = score;
    }
    final best = scores.values.reduce(math.max);
    final weights = {for (final e in scores.entries) e.key: math.exp(e.value - best)};
    final sum = weights.values.fold(0.0, (s, w) => s + w);
    final ranked = weights.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in ranked.take(limit))
        if (_evidence(e.key, name) case (final word, final support) when support > 0)
          ClassifierGuess(e.key, e.value / sum, word, support),
    ];
  }

  /// The description word seen most often in [category]'s reviewed lines.
  (String, int) _evidence(String category, List<String> words) {
    final counts = _counts[category]!;
    var best = ('', 0);
    for (final w in words) {
      final n = counts[w] ?? 0;
      if (n > best.$2) best = (w, n);
    }
    return best;
  }
}
