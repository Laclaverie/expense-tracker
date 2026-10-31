import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('every search alias belongs to a default category', () {
    final ids = {for (final c in defaultCategories) c.id};
    expect(ids, containsAll(categorySearchAliases.keys));
  });

  test('what was bought finds the category, in French or English, accents ignored', () {
    expect(matchingAlias('transport.fuel', 'essence'), 'ESSENCE');
    expect(matchingAlias('transport.fuel', 'gas'), isNotNull);
    expect(matchingAlias('housing.rent', 'loyer'), 'LOYER');
    expect(matchingAlias('health.medical', 'hôpital'), 'HOPITAL');
  });

  test('a word start or a word containing a keyword stem both match', () {
    expect(matchingAlias('transport.fuel', 'ess'), 'ESSENCE');
    expect(matchingAlias('health.pharmacy', 'pharmacien'), isNotNull, reason: 'stem PHARM');
  });

  test('seed merchants are aliases of their category', () {
    expect(matchingAlias('food.groceries', 'costco'), 'COSTCO');
    expect(matchingAlias('transport.fuel', 'petro'), 'PETRO-CANADA');
  });

  test('short or unrelated words match nothing', () {
    expect(matchingAlias('transport.fuel', 'es'), isNull);
    expect(matchingAlias('transport.fuel', 'loyer'), isNull);
    expect(matchingAlias('no.such', 'essence'), isNull);
  });

  test('matchedKeyword tells which word suggested a category', () {
    expect(matchedKeyword('ACME PHARMACIE #12'), ('PHARM', 'health.pharmacy'));
    expect(matchedKeyword('ACME CORP'), isNull);
  });
}
