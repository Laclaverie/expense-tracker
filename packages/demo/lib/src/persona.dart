/// What a made-up persona is made of ([Persona]), and the shops they visit.
/// Everything here is invented or a public chain with an invented store
/// number; amounts follow public averages for Québec, never anyone's
/// statements. The personas: `couple.dart`, `freelancer.dart`.
library;

import 'package:core/core.dart' show TargetPeriod;

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

// ------------------------------------------------------------------ a persona

/// Spending from the first to the last day (every persona).
final DateTime lifeStart = _d(2024, 10, 21);

/// Last card statement. Account statements stop at the end of the month before.
final DateTime lifeEnd = _d(2026, 10, 20);

/// Where the money comes from.
sealed class Income {
  const Income();
}

/// Net pay every other Thursday from [firstPayday].
class Salary extends Income {
  const Salary(this.firstPayday, this.pay, this.employer);

  final DateTime firstPayday;

  /// Net pay from each date on, oldest first.
  final List<(DateTime, int)> pay;
  final String employer;
}

/// What the demo databases do with a persona after importing its statements.
class ShowState {
  const ShowState({this.leftToReview = const {}, this.missingAccountStatement, this.targets = const []});

  /// Merchants never categorized: they stay to review.
  final Set<String> leftToReview;

  /// Account statement left out, so coverage notices have something to show.
  final DateTime? missingAccountStatement;

  /// Targets on the whole Desjardins CAD scope: category (null = everything),
  /// period, cents.
  final List<(String?, TargetPeriod, int)> targets;
}

/// Someone who lives two years of money: habits, bills, income, accounts.
/// Everything invented or a public chain with an invented store number.
class Persona {
  const Persona({
    required this.id,
    required this.seed,
    required this.habits,
    required this.bills,
    this.trips = const [],
    this.oneOffs = const [],
    required this.income,
    required this.rent,
    required this.landlord,
    this.friends = const [],
    this.insurer,
    this.insurance = const [],
    this.utility,
    this.taxRefund = false,
    this.cancelledTransfer,
    this.toSavings = 0,
    this.toTfsa = 0,
    this.tfsaOpened,
    this.savingsRate = .025,
    this.tfsaRate = .03,
    required this.openings,
    required this.cardAccount,
    required this.holderCard,
    this.partnerCard,
    required this.holder,
    this.partner,
    this.cardAnnualFee = 13000,
    required this.atmCaisse,
    this.accountCategories = const {},
    this.show = const ShowState(),
  });

  /// `couple`, `freelancer`: the name `demo:showcase --persona` takes.
  final String id;

  /// Seed of its [Dice]: the same seed lives the same life.
  final int seed;

  /// Everyday spending, in the order the dice roll them.
  final List<Habit> habits;
  final List<Bill> bills;
  final List<Trip> trips;
  final List<OneOff> oneOffs;
  final Income income;

  /// Rent from each date on, paid by Interac to [landlord] on the 1st.
  final List<(DateTime, int)> rent;
  final String landlord;

  /// People paid back or paying back by Interac on Saturdays.
  final List<String> friends;

  /// Home insurance taken on the 25th; null: none.
  final String? insurer;
  final List<(DateTime, int)> insurance;

  /// Electricity paid every second month (odd months, the 10th), about twice
  /// as high in winter; null: in the rent.
  final String? utility;

  /// A Québec tax refund every May 8.
  final bool taxRefund;

  /// An Interac transfer to the first friend, cancelled the same day.
  final DateTime? cancelledTransfer;

  /// To savings (`ET 1`) on the 2nd, to the TFSA (`ET 2`) on the 3rd from [tfsaOpened].
  final int toSavings, toTfsa;
  final DateTime? tfsaOpened;

  /// Annual interest rates.
  final double savingsRate, tfsaRate;

  /// Balance of each account (`EOP`, `ET 1`, `ET 2`, `CS`) before the first entry.
  final Map<String, int> openings;

  /// The card account and its cards (last 4 digits).
  final String cardAccount, holderCard;
  final String? partnerCard;
  final String holder;
  final String? partner;
  final int cardAnnualFee;

  /// Caisse printed on ATM withdrawals.
  final String atmCaisse;

  /// Category given to account lines, by counterparty (`Hydro-Québec`).
  final Map<String, String> accountCategories;
  final ShowState show;
}
