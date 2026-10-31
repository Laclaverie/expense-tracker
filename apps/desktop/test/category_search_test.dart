import 'package:expense_desktop/style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

CategoryRow row(String id, String fr, String en, {String? parent}) => CategoryRow(
  id: id,
  parentId: parent,
  nameFr: fr,
  nameEn: en,
  type: 'expense',
  color: 0,
  sortOrder: 0,
  archived: false,
);

void main() {
  final index = CategoryIndex([
    row('shopping', 'Achats', 'Shopping'),
    row('shopping.souvenirs', 'Boutique de souvenirs', 'Gift shop', parent: 'shopping'),
    row('food.cafe', 'Cafés et boulangeries', 'Coffee shops & bakeries', parent: 'food'),
  ]);

  test('a search matches the French or the English name, whatever the UI language', () {
    for (final q in ['gift', 'Gift shop', 'boutique de souvenir', 'BOUTIQUE', 'souvenirs gift']) {
      expect(index.matches('shopping.souvenirs', q), isTrue, reason: q);
    }
    expect(index.matches('shopping.souvenirs', 'coffee'), isFalse);
  });

  test('accents and case do not matter; an empty search matches everything', () {
    expect(index.matches('food.cafe', 'cafes'), isTrue);
    expect(index.matches('food.cafe', 'BOULANGERIE'), isTrue);
    expect(index.matches('food.cafe', '  '), isTrue);
    expect(index.matches('unknown', 'x'), isFalse);
  });

  test('what was bought finds a default category, and says which word matched', () {
    final fuel = CategoryIndex([row('transport.fuel', 'Essence', 'Fuel', parent: 'transport')]);
    expect(fuel.matches('transport.fuel', 'gas'), isTrue);
    expect(fuel.matchedAlias('transport.fuel', 'gas'), 'GAS');
    expect(fuel.matches('transport.fuel', 'essence'), isTrue);
    expect(fuel.matchedAlias('transport.fuel', 'essence'), isNull, reason: 'already in the name');
    expect(fuel.matches('transport.fuel', 'loyer'), isFalse);
  });
}
