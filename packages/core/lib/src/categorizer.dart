import 'imported.dart';
import 'merchant.dart';

/// User rule: when all set conditions match, assign the category.
class Rule {
  const Rule({required this.id, required this.categoryId, this.descriptionContains, this.merchantKey, this.code});

  final int id;
  final String categoryId;

  /// Case- and accent-insensitive substring of the raw description.
  final String? descriptionContains;
  final String? merchantKey;
  final String? code;

  bool matches(ImportedLine line, MerchantName merchant) =>
      (descriptionContains == null || stripAccents(line.description).contains(stripAccents(descriptionContains!))) &&
      (merchantKey == null || merchant.key == merchantKey) &&
      (code == null || line.code == code);
}

/// Where a suggestion came from, most to least trusted.
/// Where a category came from, strongest first. Stored by name.
/// [purchase]: a refund took the category of the purchase it gives back
/// (set by the import, which can look the purchase up).
enum Confidence { rule, merchant, bank, purchase, seed, keyword, hint, none }

class CategorySuggestion {
  const CategorySuggestion(this.categoryId, this.confidence);

  final String? categoryId;
  final Confidence confidence;

  /// Lines below this go to the review queue.
  bool get needsReview => confidence.index >= Confidence.hint.index;
}

/// Known merchants -> category (merchant keys from [normalizeMerchant]).
const seedMerchantCategories = {
  'TIM HORTONS': 'food.coffee',
  'STARBUCKS': 'food.coffee',
  "MCDONALD'S": 'food.fast_food',
  'A&W': 'food.fast_food',
  'SUBWAY': 'food.fast_food',
  'BURGER KING': 'food.fast_food',
  'KFC': 'food.fast_food',
  "HARVEY'S": 'food.fast_food',
  "WENDY'S": 'food.fast_food',
  'POPEYES': 'food.fast_food',
  'TACO BELL': 'food.fast_food',
  'DOMINOS': 'food.fast_food',
  'PIZZA PIZZA': 'food.fast_food',
  'TICKETMASTER': 'leisure.concerts',
  'EVENBRITE': 'leisure.events',
  'DECATHLON': 'sport.equipment',
  'SPORT EXPERT': 'sport.equipment',
  'MEC': 'sport.equipment',
  'REVENU QUEBEC': 'government.taxes',
  'AGENCE DU REVENU': 'government.taxes',
  'IGA': 'food.groceries',
  'MAXI': 'food.groceries',
  'METRO': 'food.groceries',
  'PROVIGO': 'food.groceries',
  'SUPER C': 'food.groceries',
  'COSTCO': 'food.groceries',
  'BERNARD MARCHE': 'food.groceries',
  'TOO GOOD TO GO': 'food.groceries',
  'SAQ': 'food.alcohol',
  'SHELL': 'transport.fuel',
  'PETRO-CANADA': 'transport.fuel',
  'COSTCO ESSENCE': 'transport.fuel',
  'LYFT': 'transport.rideshare',
  'UBER': 'transport.rideshare',
  'RTM': 'transport.transit',
  'STM': 'transport.transit',
  'AIRBNB': 'travel.lodging',
  'BOOKING.COM': 'travel.lodging',
  'AIR CANADA': 'travel.flights',
  'YOUTUBE': 'subscriptions.streaming',
  'NETFLIX': 'subscriptions.streaming',
  'SPOTIFY': 'subscriptions.streaming',
  'PATREON': 'subscriptions.creators',
  'INTERNET ARCHIVE': 'subscriptions.donations',
  'VIRGIN PLUS': 'telecom.mobile',
  'ROOTS': 'shopping.clothing',
  'AMAZON': 'shopping.online',
  'DESJARDINS ASSURANCES': 'housing.insurance',
  'COUCHE-TARD': 'food.groceries',
  'PREMIERE MOISSON': 'food.coffee',
  'T&T SUPERMARKET': 'food.groceries',
  'DOLLARAMA': 'shopping.other',
  'CANADIAN TIRE': 'shopping.other',
  'RENAUD-BRAY': 'shopping.other',
  'WESTJET': 'travel.flights',
  'PORTER': 'travel.flights',
  'BIXI': 'transport.transit',
  'COMMUNAUTO': 'transport.car_rental',
  'BUDGET': 'transport.car_rental',
  'STEAM': 'leisure.games',
  'BC FERRIES': 'travel.transport',
  'PARKS CANADA': 'travel.activities',
  'SAAQ': 'government.registration',
  'VRBO': 'travel.lodging',
  'EXPEDIA': 'travel.lodging',
  'HOSTELWORLD': 'travel.lodging',
};

/// Words in a description -> category. Checked in order.
const keywordCategories = [
  ('RESTAURANT', 'food.restaurants'),
  ('CUISINE', 'food.restaurants'),
  ('RAMEN', 'food.restaurants'),
  ('MICROBRASSERIE', 'food.bars'),
  ('RESTO', 'food.restaurants'),
  ('BISTRO', 'food.restaurants'),
  ('PIZZ', 'food.restaurants'),
  ('SUSHI', 'food.restaurants'),
  ('BURGER', 'food.fast_food'),
  ('POUTINE', 'food.fast_food'),
  ('SHAWARMA', 'food.fast_food'),
  ('CAFE', 'food.coffee'),
  ('COFFEE', 'food.coffee'),
  ('BOULANGERIE', 'food.coffee'),
  ('BEIGNERIE', 'food.coffee'),
  ('PATISSERIE', 'food.coffee'),
  ('BAR ', 'food.bars'),
  ('PUB', 'food.bars'),
  ('BRASSERIE', 'food.bars'),
  ('MARCHE', 'food.groceries'),
  ('EPICERIE', 'food.groceries'),
  ('ALIMENTATION', 'food.groceries'),
  ('FROMAGERIE', 'food.groceries'),
  ('SUPERMARKET', 'food.groceries'),
  ('HOTEL', 'travel.lodging'),
  ('HOSTEL', 'travel.lodging'),
  ('TRANSIT', 'transport.transit'),
  ('CONSTAT', 'government.fines'),
  ('DROIT IMMA', 'government.registration'),
  ('IMMATRICULATION', 'government.registration'),
  ('PASSEPORT', 'government.fees'),
  ('PASSPORT', 'government.fees'),
  ('CROSSFIT', 'sport.gym'),
  ('FITNESS', 'sport.gym'),
  ('YOGA', 'sport.gym'),
  ('MARATHON', 'sport.races'),
  ('DEMI-MARATHON', 'sport.races'),
  ('TRIATHLON', 'sport.races'),
  ('FESTIVAL', 'leisure.festivals'),
  ('OSHEAGA', 'leisure.festivals'),
  ('CONCERT', 'leisure.concerts'),
  ('SPECTACLE', 'leisure.concerts'),
  ('THEATRE', 'leisure.concerts'),
  ('PHARM', 'health.pharmacy'),
  ('DENTI', 'health.dental'),
  ('PARKING', 'transport.parking'),
  ('STATIONNEMENT', 'transport.parking'),
  ('CLUB', 'leisure.clubs'),
];

/// The first [keywordCategories] entry found in [description]: `(word, category)`.
/// Also tells the review screen which word suggested a category.
(String, String)? matchedKeyword(String description) {
  final text = '${stripAccents(description)} ';
  for (final entry in keywordCategories) {
    if (text.contains(entry.$1)) return entry;
  }
  return null;
}

/// Picks a category for an imported line.
///
/// Order: user rules, the merchant's remembered category, what the bank's
/// format implies, the seed merchant table, description keywords, then the
/// Bonidollars rate (3 % = food, 2 % = travel/transit/entertainment).
class Categorizer {
  Categorizer({this.rules = const [], this.merchantCategories = const {}});

  final List<Rule> rules;

  /// Merchant key -> category the user chose before.
  final Map<String, String> merchantCategories;

  CategorySuggestion categorize(ImportedLine line, MerchantName merchant) {
    for (final r in rules) {
      if (r.matches(line, merchant)) return CategorySuggestion(r.categoryId, Confidence.rule);
    }
    final remembered = merchantCategories[merchant.key];
    if (remembered != null) return CategorySuggestion(remembered, Confidence.merchant);
    if (line.categoryHint != null) return CategorySuggestion(line.categoryHint, Confidence.bank);
    final seeded = seedMerchantCategories[merchant.key];
    if (seeded != null) return CategorySuggestion(seeded, Confidence.seed);
    final keyword = matchedKeyword(line.description);
    if (keyword != null) return CategorySuggestion(keyword.$2, Confidence.keyword);
    return switch (line.bonusRate) {
      300 => const CategorySuggestion('food', Confidence.hint),
      200 => const CategorySuggestion('travel', Confidence.hint),
      _ => const CategorySuggestion(null, Confidence.none),
    };
  }
}
