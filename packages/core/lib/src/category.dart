/// Category tree: groups (no parent) and categories (parent = group).
/// Transactions are assigned leaf categories; a group id is only used as a
/// low-confidence suggestion.
class Category {
  const Category(this.id, this.nameFr, this.nameEn, {this.parentId, this.type = CategoryType.expense, this.color = 0});

  /// Stable key, e.g. `food.coffee`.
  final String id;
  final String nameFr;
  final String nameEn;
  final String? parentId;
  final CategoryType type;

  /// ARGB, set on groups (children inherit).
  final int color;

  bool get isGroup => parentId == null;

  String name(String languageCode) => languageCode == 'fr' ? nameFr : nameEn;
}

enum CategoryType {
  expense,
  income,

  /// Never counted in spending or income (transfers, card payments).
  excluded,
}

List<Category> _group(
  String id,
  String fr,
  String en,
  int color,
  List<(String, String, String)> children, {
  CategoryType type = CategoryType.expense,
}) => [
  Category(id, fr, en, type: type, color: color),
  for (final (child, cfr, cen) in children) Category('$id.$child', cfr, cen, parentId: id, type: type, color: color),
];

/// Categories removed from the defaults: id -> where their transactions move
/// when an existing database is upgraded.
const retiredCategories = {'finance.government': 'government.fees'};

/// Default tree (docs/05-categorization.md). Users can rename and add.
/// Order here is display order.
final List<Category> defaultCategories = [
  ..._group('food', 'Alimentation', 'Food', 0xFF2E7D32, [
    ('groceries', 'Épicerie', 'Groceries'),
    ('restaurants', 'Restaurants', 'Restaurants'),
    ('fast_food', 'Restauration rapide', 'Fast food'),
    ('coffee', 'Cafés et boulangeries', 'Coffee shops & bakeries'),
    ('bars', 'Bars', 'Bars'),
    ('alcohol', 'Alcool (SAQ)', 'Alcohol'),
  ]),
  ..._group('housing', 'Logement', 'Housing', 0xFF6D4C41, [
    ('rent', 'Loyer', 'Rent'),
    ('utilities', 'Services publics', 'Utilities'),
    ('insurance', 'Assurance habitation', 'Home insurance'),
    ('supplies', 'Articles ménagers', 'Household supplies'),
    ('furniture', 'Mobilier', 'Furniture'),
  ]),
  ..._group('transport', 'Transport', 'Transport', 0xFF1565C0, [
    ('transit', 'Transport en commun', 'Public transit'),
    ('rideshare', 'Taxi et VTC', 'Taxi & ride-hailing'),
    ('fuel', 'Essence', 'Fuel'),
    ('car_rental', 'Location de voiture', 'Car rental'),
    ('parking', 'Stationnement', 'Parking'),
    ('car_insurance', 'Assurance auto', 'Car insurance'),
  ]),
  ..._group('travel', 'Voyage', 'Travel', 0xFF00838F, [
    ('flights', 'Vols', 'Flights'),
    ('lodging', 'Hébergement', 'Lodging'),
    ('activities', 'Activités en voyage', 'Travel activities'),
    ('transport', 'Transport en voyage', 'Travel transport'),
  ]),
  ..._group('leisure', 'Loisirs', 'Leisure', 0xFF8E24AA, [
    ('outings', 'Sorties', 'Entertainment & outings'),
    ('clubs', 'Clubs et associations', 'Clubs & associations'),
    ('games', 'Jeux', 'Games'),
    ('events', 'Événements', 'Events'),
    ('concerts', 'Concerts et spectacles', 'Concerts & shows'),
    ('festivals', 'Festivals', 'Festivals'),
  ]),
  ..._group('sport', 'Sport', 'Sport', 0xFF00897B, [
    ('gym', 'Gym et entraînement', 'Gym & training'),
    ('races', 'Courses et événements sportifs', 'Races & sport events'),
    ('equipment', 'Équipement sportif', 'Sports equipment'),
  ]),
  ..._group('subscriptions', 'Abonnements', 'Subscriptions', 0xFFD81B60, [
    ('streaming', 'Streaming', 'Streaming'),
    ('creators', 'Créateurs', 'Creators'),
    ('software', 'Logiciels', 'Software'),
    ('donations', 'Dons', 'Donations'),
    ('other', 'Autres abonnements', 'Other subscriptions'),
  ]),
  ..._group('shopping', 'Achats', 'Shopping', 0xFFF4511E, [
    ('clothing', 'Vêtements', 'Clothing'),
    ('electronics', 'Électronique', 'Electronics'),
    ('gifts', 'Cadeaux', 'Gifts'),
    ('online', 'En ligne', 'Online'),
    ('other', 'Autres achats', 'Other shopping'),
  ]),
  ..._group('health', 'Santé', 'Health', 0xFFC62828, [
    ('pharmacy', 'Pharmacie', 'Pharmacy'),
    ('dental', 'Dentiste', 'Dental'),
    ('medical', 'Médical', 'Medical'),
    ('insurance', 'Assurance santé', 'Health insurance'),
  ]),
  ..._group('telecom', 'Télécom', 'Telecom', 0xFF546E7A, [
    ('mobile', 'Mobile', 'Mobile'),
    ('internet', 'Internet', 'Internet'),
  ]),
  ..._group('finance', 'Finances', 'Finance', 0xFF757575, [
    ('bank_fees', 'Frais bancaires', 'Bank fees'),
    ('interest_paid', 'Intérêts payés', 'Interest paid'),
  ]),
  ..._group('government', 'Gouvernement', 'Government', 0xFF3949AB, [
    ('taxes', 'Impôts et taxes', 'Taxes'),
    ('registration', 'Immatriculation et permis', 'Registration & licences'),
    ('fines', 'Amendes', 'Fines'),
    ('fees', 'Frais administratifs', 'Administrative fees'),
  ]),
  ..._group('people', 'Personnes', 'People', 0xFFFFA000, [('sent', 'Envoyé à des personnes', 'Sent to people')]),
  ..._group('income', 'Revenus', 'Income', 0xFF43A047, type: CategoryType.income, [
    ('salary', 'Salaire', 'Salary'),
    ('tax_refund', "Remboursement d'impôt", 'Tax refund'),
    ('insurance_refund', "Remboursement d'assurance", 'Insurance refund'),
    ('interest', 'Intérêts reçus', 'Interest earned'),
    ('reimbursements', 'Remboursements de proches', 'Reimbursements from friends'),
    ('rewards', 'Récompenses', 'Rewards'),
    ('other', 'Autres revenus', 'Other income'),
  ]),
  ..._group('excluded', 'Exclu', 'Excluded', 0xFF9E9E9E, type: CategoryType.excluded, [
    ('internal_transfer', 'Virement entre comptes', 'Internal transfer'),
    ('card_payment', 'Paiement carte de crédit', 'Credit card payment'),
    ('cash_withdrawal', "Retrait d'argent", 'Cash withdrawal'),
    ('savings', 'Épargne', 'Savings contribution'),
    ('external_transfer', 'Virement vers une autre banque', 'Transfer to/from another bank'),
  ]),
];
