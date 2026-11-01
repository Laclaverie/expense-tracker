/// The made-up freelancer: one person in a downtown apartment (Ville-Marie),
/// no car (STM pass, BIXI, Communauto now and then), paid by clients at
/// uneven times, quarterly tax installments, a checking account, savings and
/// one card. Shows what the couple can't: income that comes and goes.
library;

import 'package:core/core.dart' show TargetPeriod;

import 'persona.dart';

DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

const _mtl = 'MONTREAL';
const bixi = Shop('BIXI MONTREAL', _mtl, 'QC', 'transport.transit', bonus: 200);
const cowork = Shop('ESPACE COWORK MTL', _mtl, 'QC', 'subscriptions.other');
const figma = Shop('FIGMA', 'Internet', '', 'subscriptions.software');
const ramen = Shop('RAMEN DU CENTRE', _mtl, 'QC', 'food.restaurants', bonus: 300);
const camera = Shop('PHOTO CENTRE-VILLE', _mtl, 'QC', 'shopping.electronics');

final freelancer = Persona(
  id: 'freelancer',
  seed: 3141,
  habits: const [
    Habit([metro, fruiterie, metro], 4, 6000),
    Habit([cafe, boulangerie], 10, 650),
    Habit([bistro, sushi, ramen], 2.5, 3800, december: 1.4),
    Habit([bixi], 3, 450, spread: .3),
    Habit([communauto], .4, 4500, spread: .4),
    Habit([saq], .8, 2400, december: 2),
    Habit([pharmacie], .8, 2200),
    Habit([amazon], 1, 4000, spread: .6, december: 2),
  ],
  bills: [
    Bill(stm, (1, 3), [(_d(2024, 1, 1), 9700), (_d(2026, 7, 1), 10000)]),
    Bill(cowork, (1, 1), [(_d(2024, 1, 1), 22500)]),
    Bill(figma, (12, 12), [(_d(2024, 1, 1), 2000)]),
    Bill(netflix, (14, 14), [(_d(2024, 1, 1), 1899), (_d(2026, 3, 1), 2099)]),
    Bill(virgin, (12, 18), [(_d(2024, 1, 1), 4500)]),
    Bill(videotron, (8, 8), [(_d(2024, 1, 1), 6500)]),
  ],
  oneOffs: [
    OneOff(_d(2025, 4, 12), dentiste, 16500),
    OneOff(_d(2026, 2, 10), camera, 89999), // a new camera: a very large expense
  ],
  income: Clients(
    const ['STUDIO ACME', 'AGENCE EXEMPLE', 'EDITIONS DU QUAI'],
    240000,
    invoicesInMonth: {_d(2025, 8, 1): 0, _d(2026, 3, 1): 4},
  ),
  rent: [(_d(2024, 1, 1), 135000), (_d(2026, 7, 1), 139000)],
  landlord: 'Nadia Bouchard',
  friends: const ['LEA MARTIN', 'HUGO PELLETIER'],
  taxInstallments: const [TaxInstallment('Revenu Québec', 90000), TaxInstallment('Revenu Canada', 70000)],
  sweepAbove: 600000,
  openings: const {'EOP': 400000, 'ET 1': 1200000, 'CS': 500},
  cardAccount: '0003',
  holderCard: '0033',
  holder: 'CAMILLE EXEMPLE',
  atmCaisse: 'CAISSE DE VILLE-MARIE',
  accountCategories: const {'Revenu Québec': 'government.taxes', 'Revenu Canada': 'government.taxes'},
  show: const ShowState(
    leftToReview: {'RAMEN DU CENTRE'},
    targets: [('food.restaurants', TargetPeriod.month, 20000), (null, TargetPeriod.year, 4500000)],
  ),
);
