/// Finding a category by what was bought, not only by its name: `essence`,
/// `gas`, `pharmacie`, `Costco` all lead to their category.
library;

import 'categorizer.dart';
import 'merchant.dart';

/// Extra search words per category, uppercase without accents, French and
/// English. The categorizer's keywords and seed merchants are added to them
/// (see [categorySearchAliases]).
const extraSearchAliases = {
  'food.groceries': ['EPICERIE', 'GROCERY', 'SUPERMARCHE', 'MARCHE', 'NOURRITURE', 'FOOD'],
  'food.restaurants': ['RESTO', 'RESTAURANT', 'SOUPER', 'DINNER', 'DINER', 'BRUNCH'],
  'food.fast_food': ['FAST', 'RAPIDE', 'TAKEOUT', 'EMPORTER'],
  'food.coffee': ['CAFE', 'COFFEE', 'BOULANGERIE', 'BAKERY', 'PATISSERIE'],
  'food.bars': ['BIERE', 'BEER', 'PUB', 'BRASSERIE', 'BREWERY'],
  'food.alcohol': ['VIN', 'WINE', 'SAQ', 'LIQUOR'],
  'housing.rent': ['LOYER', 'RENT', 'APPARTEMENT', 'APARTMENT', 'PROPRIO', 'LANDLORD'],
  'housing.utilities': ['HYDRO', 'ELECTRICITE', 'ELECTRICITY', 'CHAUFFAGE', 'HEATING', 'EAU', 'WATER'],
  'housing.supplies': ['MENAGE', 'CLEANING', 'QUINCAILLERIE', 'HARDWARE'],
  'housing.furniture': ['MEUBLE', 'IKEA', 'FURNITURE'],
  'transport.transit': ['BUS', 'METRO', 'AUTOBUS', 'TRAIN', 'OPUS'],
  'transport.rideshare': ['TAXI', 'UBER', 'LYFT', 'VTC'],
  'transport.fuel': ['ESSENCE', 'GAS', 'GASOLINE', 'FUEL', 'CARBURANT', 'STATION'],
  'transport.car_rental': ['LOCATION', 'RENTAL', 'COMMUNAUTO'],
  'transport.parking': ['PARKING', 'STATIONNEMENT', 'PARCOMETRE'],
  'transport.car_insurance': ['AUTO', 'VOITURE', 'CAR'],
  'travel.flights': ['AVION', 'PLANE', 'VOL', 'FLIGHT', 'AIRLINE', 'AEROPORT', 'AIRPORT'],
  'travel.lodging': ['HOTEL', 'MOTEL', 'AUBERGE', 'HOSTEL', 'AIRBNB', 'CAMPING'],
  'travel.activities': ['MUSEE', 'MUSEUM', 'VISITE', 'TOUR', 'PARC'],
  'travel.transport': ['TRAVERSIER', 'FERRY', 'PEAGE', 'TOLL'],
  'leisure.outings': ['CINEMA', 'MOVIE', 'BOWLING', 'SORTIE'],
  'leisure.games': ['JEU', 'GAME', 'STEAM', 'NINTENDO', 'PLAYSTATION'],
  'leisure.concerts': ['SPECTACLE', 'SHOW', 'THEATRE', 'BILLET', 'TICKET'],
  'sport.gym': ['GYM', 'ENTRAINEMENT', 'TRAINING', 'YOGA', 'PISCINE', 'POOL'],
  'sport.equipment': ['VELO', 'BIKE', 'SKI', 'RUNNING', 'CHAUSSURE'],
  'subscriptions.streaming': ['NETFLIX', 'SPOTIFY', 'YOUTUBE', 'MUSIQUE', 'MUSIC', 'FILM'],
  'subscriptions.software': ['APP', 'APPLICATION', 'CLOUD', 'LICENCE', 'LICENSE'],
  'subscriptions.donations': ['DON', 'DONATION', 'CHARITE', 'CHARITY'],
  'shopping.clothing': ['VETEMENT', 'CLOTHES', 'CHAUSSURE', 'SHOES', 'MODE'],
  'shopping.electronics': ['ORDINATEUR', 'COMPUTER', 'TELEPHONE', 'PHONE', 'INFORMATIQUE'],
  'shopping.gifts': ['CADEAU', 'GIFT', 'ANNIVERSAIRE', 'BIRTHDAY', 'NOEL', 'CHRISTMAS'],
  'shopping.online': ['AMAZON', 'INTERNET', 'WEB'],
  'health.pharmacy': ['PHARMACIE', 'PHARMACY', 'MEDICAMENT', 'MEDICINE', 'JEAN COUTU', 'PHARMAPRIX'],
  'health.dental': ['DENTISTE', 'DENTIST', 'DENTS', 'TEETH'],
  'health.medical': ['MEDECIN', 'DOCTOR', 'CLINIQUE', 'CLINIC', 'HOPITAL', 'HOSPITAL', 'PHYSIO', 'OPTOMETRISTE'],
  'telecom.mobile': ['CELLULAIRE', 'CELL', 'FORFAIT', 'PHONE', 'TELEPHONE'],
  'telecom.internet': ['WIFI', 'FIBRE', 'FIBER'],
  'finance.bank_fees': ['FRAIS', 'FEES', 'BANQUE', 'BANK'],
  'finance.interest_paid': ['INTERET', 'INTEREST'],
  'government.taxes': ['IMPOT', 'TAX', 'TAXE'],
  'government.registration': ['PERMIS', 'LICENCE', 'SAAQ', 'PLAQUE'],
  'government.fines': ['AMENDE', 'CONTRAVENTION', 'TICKET', 'FINE'],
};

/// Search words per category: [extraSearchAliases], the categorizer's
/// [keywordCategories] and the names in [seedMerchantCategories].
final Map<String, List<String>> categorySearchAliases = () {
  final out = <String, Set<String>>{};
  void add(String category, String word) {
    final w = stripAccents(word).trim();
    if (w.length >= 3) out.putIfAbsent(category, () => {}).add(w);
  }

  for (final MapEntry(key: category, value: words) in extraSearchAliases.entries) {
    for (final w in words) {
      add(category, w);
    }
  }
  for (final (word, category) in keywordCategories) {
    add(category, word);
  }
  for (final MapEntry(key: merchant, value: category) in seedMerchantCategories.entries) {
    add(category, merchant);
  }
  return {for (final e in out.entries) e.key: e.value.toList()};
}();

/// The alias of [categoryId] that one query word matches, or null. A word
/// matches the start of an alias (`ess` -> `ESSENCE`), or an alias that is a
/// stem of the word (`pharmacie` -> `PHARM`). Words under 3 letters don't count.
String? matchingAlias(String categoryId, String queryWord) {
  final w = stripAccents(queryWord).trim();
  if (w.length < 3) return null;
  for (final a in categorySearchAliases[categoryId] ?? const <String>[]) {
    if (a.startsWith(w) || a.split(' ').any((part) => part.startsWith(w)) || (a.length >= 4 && w.startsWith(a))) {
      return a;
    }
  }
  return null;
}
