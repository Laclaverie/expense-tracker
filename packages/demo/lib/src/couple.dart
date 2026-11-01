/// The made-up couple: two adults renting in Montréal without a car, one
/// checking account, savings, a TFSA from January 2026 and a credit card with
/// two cards. Its statements are also the bank plug-ins' fixtures
/// (`demo:fixtures`): a change here shows in `fixtures_test.dart`.
library;

import 'package:core/core.dart' show TargetPeriod;

import 'persona.dart';

DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

final couple = Persona(
  id: 'couple',
  seed: 2026,
  habits: const [
    Habit([iga, metro, iga, fruiterie], 5.5, 9500),
    Habit([cafe, boulangerie, timHortons], 4, 1150, partner: .4),
    Habit([bistro, pizzeria, sushi, tablee], 3, 6400, december: 1.6),
    Habit([aw, subway], 1.5, 1450),
    Habit([saq], 1.6, 3600, december: 2),
    Habit([pharmacie], 1.2, 2800),
    Habit([amazon, dollarama, canadianTire, simons], 2.2, 4800, spread: .6, december: 2.5),
    Habit([communauto, uber], 1.2, 3100, spread: .5),
    Habit([cinema, ticketmaster, librairie], .9, 4200, spread: .5, december: 2),
    // Once a month, at Costco.
    Habit([costco], 1, 21000, spread: .25, partner: .5),
  ],
  bills: [
    Bill(stm, (1, 3), [(_d(2024, 1, 1), 9700), (_d(2026, 7, 1), 10000)]),
    Bill(videotron, (8, 8), [(_d(2024, 1, 1), 7500)]),
    Bill(apple, (5, 5), [(_d(2024, 1, 1), 399)]),
    // Price change in March 2026: the recurring payment follows it.
    Bill(netflix, (14, 14), [(_d(2024, 1, 1), 1899), (_d(2026, 3, 1), 2099)]),
    Bill(spotify, (22, 22), [(_d(2024, 1, 1), 1199)]),
    // Paid by hand somewhere between the 12th and the 18th; roaming made two bills higher:
    // May (before the alert window: "past unusual payment") and September (an alert).
    Bill(
      virgin,
      (12, 18),
      [
        (_d(2024, 1, 1), 4500),
        (_d(2026, 5, 1), 5928),
        (_d(2026, 6, 1), 4500),
        (_d(2026, 9, 1), 7248),
        (_d(2026, 10, 1), 4500),
      ],
    ),
    // Cancelled in spring 2026: shows as a stopped recurring payment.
    Bill(gym, (1, 1), [(_d(2024, 1, 1), 3999)], until: _d(2026, 4, 30)),
  ],
  trips: [
    Trip(_d(2025, 7, 5), 6, const Shop('AUBERGE DU PHARE', 'GASPE', 'QC', 'travel.lodging'), 16900, const [
      (Shop('RESTAURANT LE MARIN', 'GASPE', 'QC', 'food.restaurants', bonus: 300), 7400),
      (Shop('PARC NATIONAL FORILL', 'GASPE', 'QC', 'travel.activities'), 2400),
      (Shop('PETRO-CANADA 4410', 'MATANE', 'QC', 'transport.fuel', bonus: 200), 6200),
      (Shop('CAFE DU QUAI', 'PERCE', 'QC', 'food.coffee', bonus: 300), 1300),
    ]),
    Trip(
      _d(2026, 5, 14),
      4,
      const Shop('HARBOR VIEW HOTEL', 'BOSTON', 'MA', 'travel.lodging'),
      21900,
      const [
        (Shop('NORTH END TRATTORIA', 'BOSTON', 'MA', 'food.restaurants', bonus: 300), 6800),
        (Shop('MBTA CHARLIECARD', 'BOSTON', 'MA', 'travel.transport'), 1100),
        (Shop('AQUARIUM GIFT SHOP', 'BOSTON', 'MA', 'travel.activities'), 3400),
      ],
      currency: 'USD',
      rate: 1.3712,
    ),
  ],
  oneOffs: [
    OneOff(_d(2025, 3, 22), dentiste, 18500),
    OneOff(_d(2025, 9, 27), dentiste, 21000),
    OneOff(_d(2025, 12, 13), bestBuy, 32999),
    OneOff(_d(2026, 1, 30), amazon, -4799), // refund of a return
    OneOff(_d(2026, 3, 21), dentiste, 19500),
    OneOff(_d(2026, 10, 3), bestBuy, 149999), // a new laptop: a very large expense
    OneOff(
      _d(2026, 10, 6),
      const Shop('KICKSTARTER.COM', 'BROOKLYN', 'NY', 'shopping.online'),
      2500,
      currency: 'USD',
      rate: 1.3891,
    ),
  ],
  income: Salary(_d(2024, 10, 24), [(_d(2024, 1, 1), 196000), (_d(2026, 4, 1), 203000)], 'LOGICIELS BOREAL INC'),
  rent: [(_d(2024, 1, 1), 145000), (_d(2026, 7, 1), 149500)],
  landlord: 'Martin Lavoie',
  friends: const ['JULIE TREMBLAY', 'MARC GAGNON', 'SOPHIE ROY'],
  insurer: 'ASSURANCES BOREALE',
  insurance: [(_d(2024, 1, 1), 3180), (_d(2026, 1, 1), 3340)],
  utility: 'Hydro-Québec',
  taxRefund: true,
  cancelledTransfer: _d(2026, 9, 12),
  toSavings: 55000,
  toTfsa: 40000,
  tfsaOpened: _d(2026, 1, 3),
  openings: const {'EOP': 240000, 'ET 1': 850000, 'ET 2': 0, 'CS': 500},
  cardAccount: '0001',
  holderCard: '0011',
  partnerCard: '0022',
  holder: 'ALEX EXEMPLE',
  partner: 'SAM EXEMPLE',
  atmCaisse: 'CAISSE DU PLATEAU',
  accountCategories: const {'Hydro-Québec': 'housing.utilities', 'ASSURANCES BOREALE': 'housing.insurance'},
  show: ShowState(
    leftToReview: const {'LIBRAIRIE DU PLATEAU', 'CINEMA DU QUARTIER'},
    missingAccountStatement: _d(2026, 6, 30),
    targets: const [
      ('food.groceries', TargetPeriod.month, 85000),
      ('food.restaurants', TargetPeriod.month, 25000),
      (null, TargetPeriod.month, 400000),
    ],
  ),
);
