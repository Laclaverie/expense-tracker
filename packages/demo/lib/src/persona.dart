/// The made-up household: two adults renting in Montréal, one checking
/// account, savings, a TFSA from January 2026 and a credit card with two
/// cards. Everything here is invented or a public chain with an invented store
/// number; amounts follow public averages for a Québec household, never anyone's
/// statements. Edit freely: tests check what the app must find, not exact values.
library;

/// A place that takes the card.
class Shop {
  const Shop(this.name, this.city, this.region, this.category, {this.bonus = 100});

  /// As the card network prints it: at most 21 characters.
  final String name;

  /// At most 13 characters; with [region] empty, a word like `Internet`.
  final String city;

  /// Province, state or country code; empty when the network prints none.
  final String region;

  /// Category the household gives it.
  final String category;

  /// Rewards rate in basis points.
  final int bonus;

  String get location => region.isEmpty ? city : '$city $region';
}

/// Everyday spending: [perMonth] visits on average, about [typical] cents each.
class Habit {
  const Habit(this.shops, this.perMonth, this.typical, {this.spread = .35, this.partner = .3, this.december = 1});

  final List<Shop> shops;
  final double perMonth;
  final int typical;
  final double spread;

  /// Share of visits paid with the second card.
  final double partner;

  /// Visits multiplier in December (gifts, parties).
  final double december;
}

/// A bill on the card every [everyMonths] months, between [days].
class Bill {
  const Bill(this.shop, this.days, this.prices, {this.until});

  final Shop shop;

  /// First and last day of the month it can be paid (a bill paid by hand drifts).
  final (int, int) days;

  /// Price from each date on, oldest first.
  final List<(DateTime, int)> prices;

  /// Cancelled after this date.
  final DateTime? until;

  int priceOn(DateTime d) {
    var p = prices.first.$2;
    for (final (from, cents) in prices) {
      if (!d.isBefore(from)) p = cents;
    }
    return p;
  }
}

/// A trip: [nights] at [hotel], restaurants and activities around it.
class Trip {
  const Trip(this.start, this.nights, this.hotel, this.perNight, this.around, {this.currency, this.rate});

  final DateTime start;
  final int nights;
  final Shop hotel;
  final int perNight;

  /// Places visited during the trip, one or two a day.
  final List<(Shop, int)> around;

  /// Paid in this currency (`USD`), converted at [rate].
  final String? currency;
  final double? rate;
}

/// One purchase on a given day. Negative [cents] = refund. With [currency],
/// [cents] are in that currency, converted at [rate].
class OneOff {
  const OneOff(this.date, this.shop, this.cents, {this.currency, this.rate});

  final DateTime date;
  final Shop shop;
  final int cents;
  final String? currency;
  final double? rate;
}

DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

const _mtl = 'MONTREAL';

// ------------------------------------------------------------------- shops

const iga = Shop('IGA EXTRA #8123', _mtl, 'QC', 'food.groceries', bonus: 300);
const metro = Shop('METRO #224', _mtl, 'QC', 'food.groceries', bonus: 300);
const costco = Shop('COSTCO WHOLESALE W123', 'LAVAL', 'QC', 'food.groceries', bonus: 300);
const fruiterie = Shop('FRUITERIE DU QUARTIER', _mtl, 'QC', 'food.groceries', bonus: 300);
const bistro = Shop('BISTRO DU PARC', _mtl, 'QC', 'food.restaurants', bonus: 300);
const pizzeria = Shop('PIZZERIA NAPOLI', _mtl, 'QC', 'food.restaurants', bonus: 300);
const sushi = Shop('SUSHI MAKI BAR', _mtl, 'QC', 'food.restaurants', bonus: 300);
const tablee = Shop('RESTO LA TABLEE', _mtl, 'QC', 'food.restaurants', bonus: 300);
const cafe = Shop('CAFE DU COIN', _mtl, 'QC', 'food.coffee', bonus: 300);
const boulangerie = Shop('BOULANGERIE LA MIE', _mtl, 'QC', 'food.coffee', bonus: 300);
const timHortons = Shop('TIM HORTONS #4521', _mtl, 'QC', 'food.coffee', bonus: 300);
const aw = Shop('A&W #2231', _mtl, 'QC', 'food.fast_food', bonus: 300);
const subway = Shop('SUBWAY 31245', _mtl, 'QC', 'food.fast_food', bonus: 300);
const saq = Shop('SAQ 23045', _mtl, 'QC', 'food.alcohol');
const pharmacie = Shop('PHARMAPRIX #1234', _mtl, 'QC', 'health.pharmacy');
const dentiste = Shop('DENTISTE DU PARC', _mtl, 'QC', 'health.dental');
const stm = Shop('STM CARTE OPUS', _mtl, 'QC', 'transport.transit', bonus: 200);
const communauto = Shop('COMMUNAUTO', _mtl, 'QC', 'transport.car_rental', bonus: 200);
const uber = Shop('UBER CANADA/UBERTRIP', 'TORONTO', 'ON', 'transport.rideshare', bonus: 200);
const netflix = Shop('NETFLIX.COM', 'TORONTO', 'ON', 'subscriptions.streaming');
const spotify = Shop('SPOTIFY', 'Internet', '', 'subscriptions.streaming');
const apple = Shop('APPLE.COM/BILL', 'TORONTO', 'ON', 'subscriptions.software');
const virgin = Shop('VIRGIN PLUS', _mtl, 'QC', 'telecom.mobile');
const videotron = Shop('VIDEOTRON', _mtl, 'QC', 'telecom.internet');
const gym = Shop('CLUB SPORTIF BOREAL', _mtl, 'QC', 'sport.gym');
const amazon = Shop('AMAZON.CA', 'AMAZON.CA', 'ON', 'shopping.online');
const dollarama = Shop('DOLLARAMA #123', _mtl, 'QC', 'housing.supplies');
const canadianTire = Shop('CANADIAN TIRE #456', _mtl, 'QC', 'housing.supplies');
const simons = Shop('SIMONS', _mtl, 'QC', 'shopping.clothing');
const cinema = Shop('CINEMA DU QUARTIER', _mtl, 'QC', 'leisure.outings');
const ticketmaster = Shop('TICKETMASTER CANADA', 'TORONTO', 'ON', 'leisure.concerts');
const bestBuy = Shop('BEST BUY #940', _mtl, 'QC', 'shopping.electronics');
const librairie = Shop('LIBRAIRIE DU PLATEAU', _mtl, 'QC', 'shopping.gifts');

// ------------------------------------------------------------- the household

/// Spending from the first to the last day.
final DateTime lifeStart = _d(2024, 10, 21);

/// Last card statement. Account statements stop at the end of the month before.
final DateTime lifeEnd = _d(2026, 10, 20);

const habits = [
  Habit([iga, metro, iga, fruiterie], 5.5, 9500),
  Habit([cafe, boulangerie, timHortons], 4, 1150, partner: .4),
  Habit([bistro, pizzeria, sushi, tablee], 3, 6400, december: 1.6),
  Habit([aw, subway], 1.5, 1450),
  Habit([saq], 1.6, 3600, december: 2),
  Habit([pharmacie], 1.2, 2800),
  Habit([amazon, dollarama, canadianTire, simons], 2.2, 4800, spread: .6, december: 2.5),
  Habit([communauto, uber], 1.2, 3100, spread: .5),
  Habit([cinema, ticketmaster, librairie], .9, 4200, spread: .5, december: 2),
];

/// Once a month, at Costco.
const costcoRun = Habit([costco], 1, 21000, spread: .25, partner: .5);

final bills = [
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
];

final trips = [
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
];

final oneOffs = [
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
];

/// Every other Thursday from this date, net pay.
final DateTime firstPayday = _d(2024, 10, 24);
final List<(DateTime, int)> pay = [(_d(2024, 1, 1), 196000), (_d(2026, 4, 1), 203000)];
const employer = 'LOGICIELS BOREAL INC';

final List<(DateTime, int)> rent = [(_d(2024, 1, 1), 145000), (_d(2026, 7, 1), 149500)];
const landlord = 'Martin Lavoie';

/// Friends paid back or paying back by Interac.
const friends = ['JULIE TREMBLAY', 'MARC GAGNON', 'SOPHIE ROY'];

/// Home insurance, taken by the insurer each month.
const insurer = 'ASSURANCES BOREALE';
final List<(DateTime, int)> insurance = [(_d(2024, 1, 1), 3180), (_d(2026, 1, 1), 3340)];

/// Electricity every second month (higher in winter).
const utility = 'Hydro-Québec';

/// To savings on the 2nd, to the TFSA on the 3rd from January 2026.
const toSavings = 55000, toTfsa = 40000;
final DateTime tfsaOpened = _d(2026, 1, 3);

/// Annual savings interest rates.
const savingsRate = .025, tfsaRate = .03;

/// Opening balances (cents).
const openings = {'EOP': 240000, 'ET 1': 850000, 'ET 2': 0, 'CS': 500};

/// The card account and its two cards.
const cardAccount = '0001', holderCard = '0011', partnerCard = '0022';
const holder = 'ALEX EXEMPLE', partner = 'SAM EXEMPLE';
const cardAnnualFee = 13000;
