import 'dice.dart';
import 'life.dart';
import 'persona.dart';

/// Lives the persona from [lifeStart] to [lifeEnd]: rules and habits, with a
/// little seeded variation (the same [seed] gives the same life).
Life liveHousehold({int seed = 2026}) {
  final dice = Dice(seed);
  final card = <CardEntry>[..._spending(dice), ..._trips(dice), ..._oneOffs(dice), ..._cardOperations()];
  final statements = [
    for (
      var m = DateTime.utc(lifeStart.year, lifeStart.month + 1, 20);
      !m.isAfter(lifeEnd);
      m = DateTime.utc(m.year, m.month + 1, 20)
    )
      m,
  ];
  final payments = _settleCard(card, statements);
  card.addAll(payments.map((p) => p.$2));
  card.sort((a, b) => a.posted.compareTo(b.posted));
  return Life(
    accountEntries: _accounts(dice, [for (final p in payments) p.$1]),
    cardEntries: card,
    openings: openings,
    cardStatementDates: statements,
    accountCategories: const {utility: 'housing.utilities', insurer: 'housing.insurance'},
  );
}

DateTime _day(DateTime d, int days) => DateTime.utc(d.year, d.month, d.day + days);

Iterable<DateTime> _days(DateTime from, DateTime to) sync* {
  for (var d = from; !d.isAfter(to); d = _day(d, 1)) {
    yield d;
  }
}

CardEntry _purchase(Dice dice, DateTime date, Shop shop, int cents, {String card = holderCard, Foreign? foreign}) =>
    CardEntry(
      date: date,
      posted: _day(date, dice.range(0, 2)),
      card: card,
      merchant: shop.name,
      location: shop.location,
      amount: -cents,
      bonusRate: foreign == null ? shop.bonus : 100,
      foreign: foreign,
      category: shop.category,
    );

Iterable<CardEntry> _spending(Dice dice) sync* {
  for (final day in _days(lifeStart, lifeEnd)) {
    for (final h in [...habits, costcoRun]) {
      final perDay = h.perMonth * (day.month == 12 ? h.december : 1) / 30.4;
      if (!dice.chance(perDay)) continue;
      final card = dice.chance(h.partner) ? partnerCard : holderCard;
      yield _purchase(dice, day, dice.pick(h.shops), dice.around(h.typical, h.spread), card: card);
    }
    for (final b in bills) {
      if (b.until != null && day.isAfter(b.until!)) continue;
      // A bill paid by hand: a day picked once per month, inside its window.
      final (first, last) = b.days;
      final payDay =
          first + (Dice(day.year * 100 + day.month + b.shop.name.length).unit() * (last - first + 1)).floor();
      if (day.day == payDay) yield _purchase(dice, day, b.shop, b.priceOn(day));
    }
  }
}

Iterable<CardEntry> _trips(Dice dice) sync* {
  for (final t in trips) {
    Foreign? foreign(int cents) => t.currency == null ? null : Foreign(cents, t.currency!, t.rate!);
    int cad(int cents) => t.rate == null ? cents : (cents * t.rate!).round();
    for (var n = 0; n < t.nights; n++) {
      final day = _day(t.start, n);
      for (final (shop, typical) in [t.around[n % t.around.length], dice.pick(t.around)]) {
        final cents = dice.around(typical, .3);
        yield _purchase(dice, day, shop, cad(cents), foreign: foreign(cents));
      }
    }
    // The hotel is paid when leaving.
    final stay = t.perNight * t.nights;
    yield _purchase(dice, _day(t.start, t.nights), t.hotel, cad(stay), foreign: foreign(stay));
  }
}

Iterable<CardEntry> _oneOffs(Dice dice) sync* {
  for (final o in oneOffs) {
    final foreign = o.currency == null ? null : Foreign(o.cents, o.currency!, o.rate!);
    yield _purchase(dice, o.date, o.shop, foreign == null ? o.cents : (o.cents * o.rate!).round(), foreign: foreign);
  }
}

/// Annual fee every February, rewards paid out every January.
Iterable<CardEntry> _cardOperations() sync* {
  for (var y = lifeStart.year; y <= lifeEnd.year; y++) {
    final fee = DateTime.utc(y, 2, 3), rewards = DateTime.utc(y, 1, 6);
    if (fee.isAfter(lifeStart) && fee.isBefore(lifeEnd)) {
      yield CardEntry(
        date: fee,
        posted: fee,
        card: cardAccount,
        merchant: 'FRAIS ANNUELS',
        amount: -cardAnnualFee,
        operation: true,
      );
    }
    if (rewards.isAfter(lifeStart) && rewards.isBefore(lifeEnd)) {
      yield CardEntry(
        date: rewards,
        posted: rewards,
        card: cardAccount,
        merchant: 'CRÉDIT BONIDOLLARS EN ARGENT',
        amount: 5000,
        operation: true,
      );
    }
  }
}

/// Each statement's new balance is paid from checking 4 days after it closes:
/// the checking line, and the card's credit on the next statement.
List<(AccountEntry, CardEntry)> _settleCard(List<CardEntry> card, List<DateTime> statements) {
  final out = <(AccountEntry, CardEntry)>[];
  var balance = 0; // owed, positive
  var from = lifeStart;
  for (final closing in statements) {
    for (final e in card) {
      if (!e.posted.isBefore(from) && !e.posted.isAfter(closing)) balance -= e.amount;
    }
    for (final (_, c) in out) {
      if (!c.posted.isBefore(from) && !c.posted.isAfter(closing)) balance -= c.amount;
    }
    from = _day(closing, 1);
    if (balance <= 0) continue;
    final paid = _day(closing, 4);
    out.add((
      AccountEntry('EOP', paid, 'PWW', 'Paiement facture - AccèsD Internet / Odyssée World Elite Mastercard', -balance),
      CardEntry(
        date: paid,
        posted: _day(paid, 1),
        card: cardAccount,
        merchant: 'PAIEMENT CAISSE',
        amount: balance,
        operation: true,
      ),
    ));
  }
  return out;
}

int _priceOn(List<(DateTime, int)> prices, DateTime d) => Bill(stm, (1, 1), prices).priceOn(d);

/// Checking, savings and TFSA, day by day, with savings interest at month end.
List<AccountEntry> _accounts(Dice dice, List<AccountEntry> cardPayments) {
  final out = <AccountEntry>[];
  final balance = {...openings};
  void add(String account, DateTime d, String code, String text, int cents) {
    out.add(AccountEntry(account, d, code, text, cents));
    balance[account] = balance[account]! + cents;
  }

  final firstMonth = DateTime.utc(lifeStart.year, lifeStart.month + 1);
  final lastDay = DateTime.utc(lifeEnd.year, lifeEnd.month, 0);
  var nextAtm = _day(firstMonth, 9);
  for (final d in _days(firstMonth, lastDay)) {
    final weekday = d.weekday;
    if (d.difference(firstPayday).inDays % 14 == 0) add('EOP', d, 'DI', 'Paie / $employer', _priceOn(pay, d));
    if (d.day == 1) add('EOP', d, 'VMW', 'Virement envoyé à / $landlord /Loyer', -_priceOn(rent, d));
    if (d.day == 2) {
      add('EOP', d, 'VIW', 'Virement - AccèsD Internet / à ET 1', -toSavings);
      add('ET 1', d, 'VIW', 'Virement - AccèsD Internet / de EOP', toSavings);
    }
    if (d.day == 3 && !d.isBefore(tfsaOpened)) {
      add('EOP', d, 'VIW', 'Virement - AccèsD Internet / à ET 2', -toTfsa);
      add('ET 2', d, 'VIW', 'Virement - AccèsD Internet / de EOP', toTfsa);
    }
    if (d.day == 25) add('EOP', d, 'RA', 'Prélèvement / $insurer', -_priceOn(insurance, d));
    if (d.day == 10 && d.month.isOdd) {
      // Bimonthly electricity bill, about twice as high in winter.
      final winter = d.month <= 3 || d.month >= 11;
      add('EOP', d, 'PWW', 'Paiement facture - AccèsD Internet / $utility', -dice.around(winter ? 21000 : 9500, .12));
    }
    for (final p in cardPayments) {
      if (p.date == d) add(p.account, d, p.code, p.description, p.amount);
    }
    if (d == nextAtm) {
      add('EOP', d, 'IRGA', 'Retrait au GA / CAISSE DU PLATEAU', -dice.pick([4000, 6000, 8000, 10000]));
      nextAtm = _day(d, dice.range(30, 50));
    }
    if (weekday == DateTime.saturday && dice.chance(.35)) {
      final friend = dice.pick(friends);
      if (dice.chance(.55)) {
        add('EOP', d, 'VMW', 'Virement Interac à / $friend/', -dice.around(3500, .5));
      } else {
        add('EOP', d, 'VMW', 'Virement Interac de / $friend/', dice.around(2800, .5));
      }
    }
    // Tax refunds in May, a cancelled transfer in September 2026.
    if (d.month == 5 && d.day == 8) {
      add('EOP', d, 'DI', 'Dépôt direct / Remboursement impôt Québec', dice.around(64000, .2));
    }
    if (d == DateTime.utc(2026, 9, 12)) {
      add('EOP', d, 'VMW', 'Virement Interac à / ${friends.first}/', -4000);
      add('EOP', d, 'VMW', 'Annulation - Virement Interac à / ${friends.first}/', 4000);
    }
    if (_day(d, 1).day == 1) {
      add('EOP', d, 'FIX', "Frais fixes d'utilisation", -395);
      final savings = (balance['ET 1']! * savingsRate / 12).round();
      if (savings > 0) add('ET 1', d, 'IET', 'Intérêt sur ET', savings);
      final tfsa = (balance['ET 2']! * tfsaRate / 12).round();
      if (tfsa > 0) add('ET 2', d, 'IET', 'Intérêt sur ET', tfsa);
    }
  }
  return out;
}
