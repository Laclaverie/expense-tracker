import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  final classifier = CategoryClassifier.train([
    ('ACME SUSHI BAR', 'MONTREAL QC', 'food.restaurants'),
    ('SQ *TOKYO SUSHI', 'LAVAL QC', 'food.restaurants'),
    ('PIZZERIA DEMO', 'MONTREAL QC', 'food.restaurants'),
    ('TOKYO GRILL', 'LAVAL QC', 'food.restaurants'),
    ('EXEMPLE GAZ #12', 'LONGUEUIL QC', 'transport.fuel'),
    ('STATION DEMO GAZ', 'MONTREAL QC', 'transport.fuel'),
    ('MARCHE EXEMPLE', 'MONTREAL QC', 'food.groceries'),
    ('SQ *CAFE TEST', 'CHARLOTTETOWN PE', 'travel.activities'),
    ('MUSEE TEST', 'CHARLOTTETOWN PE', 'travel.activities'),
  ]);

  test('words of a line: no store numbers, city kept, province dropped', () {
    expect(classifierWords('SQ *HOJO\'S SUSHI #12', 'CHARLOTTETOWN PE'), ['SQ', "HOJO'S", 'SUSHI', '@CHARLOTTETOWN']);
    expect(classifierWords('Café Été', null), ['CAFE', 'ETE']);
  });

  test('a new merchant sharing a word goes to that word\'s category, with the word as evidence', () {
    final guess = classifier.suggest('NEW SUSHI PLACE', 'QUEBEC QC').first;
    expect(guess.categoryId, 'food.restaurants');
    expect((guess.word, guess.support), ('SUSHI', 2));
    expect(guess.probability, greaterThan(0.5));
  });

  test('the city alone suggests nothing; with a shared name word it helps', () {
    expect(classifier.suggest('BOULANGERIE INCONNUE', 'CHARLOTTETOWN PE'), isEmpty);
    expect(classifier.suggest('SQ *INCONNU', 'CHARLOTTETOWN PE').first.categoryId, 'travel.activities');
  });

  test('stays quiet when no word was ever seen, or nothing was learned', () {
    expect(classifier.suggest('ZZZ QQQ', 'NOWHERE ZZ'), isEmpty);
    expect(CategoryClassifier().suggest('ACME SUSHI', null), isEmpty);
  });

  test('learns at once: a new category works after a few lines', () {
    final c = CategoryClassifier.train([('ACME SUSHI', null, 'food.restaurants')]);
    expect(c.suggest('VELO DEMO', null), isEmpty);
    c.add('VELO EXEMPLE', null, 'sport.equipment');
    c.add('VELO TEST', null, 'sport.equipment');
    expect(c.suggest('VELO DEMO', null).first.categoryId, 'sport.equipment');
  });
}
