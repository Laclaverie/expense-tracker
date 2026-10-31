import 'package:pdf_words/pdf_words.dart';
import 'package:test/test.dart';

void main() {
  group('groupRows', () {
    test('groups words by baseline and sorts them left to right', () {
      final rows = groupRows(const [Word('b', 50, 55, 100.4), Word('c', 10, 15, 120), Word('a', 10, 15, 100)]);
      expect(rows.map((r) => r.text), ['a b', 'c']);
    });

    test('merges space thousands separator', () {
      final rows = groupRows(const [
        Word('2', 543, 548, 10),
        Word('098.68', 551, 575, 10),
        Word('5', 400, 405, 10),
        Word('Paie', 108, 125, 10),
      ]);
      expect(rows.single.texts, ['Paie', '5', '2098.68']);
    });

    test('does not merge distant numbers', () {
      final rows = groupRows(const [Word('15', 55, 63, 10), Word('100.00', 400, 425, 10)]);
      expect(rows.single.texts, ['15', '100.00']);
    });
  });

  test('json round trip', () {
    const doc = DocumentWords([
      PageWords(612, 792, [Word('Solde', 108.04, 129.96, 254.55)]),
    ]);
    final back = DocumentWords.fromJson(doc.toJson());
    expect(back.pages.single.words.single.toJson(), ['Solde', 108.0, 130.0, 254.6]);
  });
}
