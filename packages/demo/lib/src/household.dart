import 'couple.dart';
import 'dice.dart';
import 'life.dart';
import 'persona.dart';

/// Lives [persona] (the couple by default) from [lifeStart] to [lifeEnd]:
/// rules and habits, with a little seeded variation (the same seed gives the
/// same life).
Life liveHousehold({Persona? persona, int? seed}) {
  final p = persona ?? couple;
  final dice = Dice(seed ?? p.seed);
  final card = <CardEntry>[..._spending(p, dice), ..._trips(p, dice), ..._oneOffs(p, dice), ..._cardOperations(p)];
  final statements = [
    for (
      var m = DateTime.utc(lifeStart.year, lifeStart.month + 1, 20);
      !m.isAfter(lifeEnd);
      m = DateTime.utc(m.year, m.month + 1, 20)
    )
      m,
  ];
  final payments = _settleCard(p, card, statements);
  card.addAll(payments.map((e) => e.$2));
  card.sort((a, b) => a.posted.compareTo(b.posted));
  return Life(
    persona: p,
    accountEntries: _accounts(p, dice, [for (final e in payments) e.$1]),
    cardEntries: card,
    openings: p.openings,
    cardStatementDates: statements,
    accountCategories: p.accountCategories,
  );
}

DateTime _day(DateTime d, int days) => DateTime.utc(d.year, d.month, d.day + days);

Iterable<DateTime> _days(DateTime from, DateTime to) sync* {
  for (var d = from; !d.isAfter(to); d = _day(d, 1)) {
    yield d;
  }
}

CardEntry _purchase(Dice dice, DateTime date, Shop shop, int cents, {required String card, Foreign? foreign}) =>
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

Iterable<CardEntry> _spending(Persona p, Dice dice) sync* {
  for (final day in _days(lifeStart, lifeEnd)) {
    for (final h in p.habits) {
      final perDay = h.perMonth * (day.month == 12 ? h.december : 1) / 30.4;
      if (!dice.chance(perDay)) continue;
      final card = (dice.chance(h.partner) ? p.partnerCard : null) ?? p.holderCard;
      yield _purchase(dice, day, dice.pick(h.shops), dice.around(h.typical, h.spread), card: card);
    }
    for (final b in p.bills) {
      if (b.until != null && day.isAfter(b.until!)) continue;
      // A bill paid by hand: a day picked once per month, inside its window.
      final (first, last) = b.days;
      final payDay =
          first + (Dice(day.year * 100 + day.month + b.shop.name.length).unit() * (last - first + 1)).floor();
      if (day.day == payDay) yield _purchase(dice, day, b.shop, b.priceOn(day), card: p.holderCard);
    }
  }
}

Iterable<CardEntry> _trips(Persona p, Dice dice) sync* {
  for (final t in p.trips) {
    Foreign? foreign(int cents) => t.currency == null ? null : Foreign(cents, t.currency!, t.rate!);
    int cad(int cents) => t.rate == null ? cents : (cents * t.rate!).round();
    for (var n = 0; n < t.nights; n++) {
      final day = _day(t.start, n);
      for (final (shop, typical) in [t.around[n % t.around.length], dice.pick(t.around)]) {
        final cents = dice.around(typical, .3);
        yield _purchase(dice, day, shop, cad(cents), card: p.holderCard, foreign: foreign(cents));
      }
    }
    // The hotel is paid when leaving.
    final stay = t.perNight * t.nights;
    yield _purchase(dice, _day(t.start, t.nights), t.hotel, cad(stay), card: p.holderCard, foreign: foreign(stay));
  }
}

Iterable<CardEntry> _oneOffs(Persona p, Dice dice) sync* {
  for (final o in p.oneOffs) {
    final foreign = o.currency == null ? null : Foreign(o.cents, o.currency!, o.rate!);
    final cents = foreign == null ? o.cents : (o.cents * o.rate!).round();
    yield _purchase(dice, o.date, o.shop, cents, card: p.holderCard, foreign: foreign);
  }
}

/// Annual fee every February, rewards paid out every January.
Iterable<CardEntry> _cardOperations(Persona p) sync* {
  for (var y = lifeStart.year; y <= lifeEnd.year; y++) {
    final fee = DateTime.utc(y, 2, 3), rewards = DateTime.utc(y, 1, 6);
    if (fee.isAfter(lifeStart) && fee.isBefore(lifeEnd)) {
      yield CardEntry(
        date: fee,
        posted: fee,
        card: p.cardAccount,
        merchant: 'FRAIS ANNUELS',
        amount: -p.cardAnnualFee,
        operation: true,
      );
    }
    if (rewards.isAfter(lifeStart) && rewards.isBefore(lifeEnd)) {
      yield CardEntry(
        date: rewards,
        posted: rewards,
        card: p.cardAccount,
        merchant: 'CRÉDIT BONIDOLLARS EN ARGENT',
        amount: 5000,
        operation: true,
      );
    }
  }
}

/// Each statement's new balance is paid from checking 4 days after it closes:
/// the checking line, and the card's credit on the next statement.
List<(AccountEntry, CardEntry)> _settleCard(Persona p, List<CardEntry> card, List<DateTime> statements) {
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
        card: p.cardAccount,
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
List<AccountEntry> _accounts(Persona p, Dice dice, List<AccountEntry> cardPayments) {
  final out = <AccountEntry>[];
  final balance = {...p.openings};
  void add(String account, DateTime d, String code, String text, int cents) {
    out.add(AccountEntry(account, d, code, text, cents));
    balance[account] = (balance[account] ?? 0) + cents;
  }

  final firstMonth = DateTime.utc(lifeStart.year, lifeStart.month + 1);
  final lastDay = DateTime.utc(lifeEnd.year, lifeEnd.month, 0);
  var nextAtm = _day(firstMonth, 9);
  final invoices = <DateTime, List<(String, int)>>{};
  for (final d in _days(firstMonth, lastDay)) {
    final weekday = d.weekday;
    switch (p.income) {
      case Salary(:final firstPayday, :final pay, :final employer):
        if (d.difference(firstPayday).inDays % 14 == 0) add('EOP', d, 'DI', 'Paie / $employer', _priceOn(pay, d));
      case Clients(:final names, :final typical, :final spread, :final invoicesInMonth):
        if (d.day == 1) {
          // Mostly one or two invoices paid a month, sometimes none or three.
          final int count = invoicesInMonth[d] ?? dice.pick(const [0, 1, 1, 1, 2, 2, 3]);
          for (var i = 0; i < count; i++) {
            var day = DateTime.utc(d.year, d.month, dice.range(3, 26));
            if (day.weekday == DateTime.saturday) day = _day(day, 2);
            if (day.weekday == DateTime.sunday) day = _day(day, 1);
            invoices.putIfAbsent(day, () => []).add((dice.pick(names), dice.around(typical, spread)));
          }
        }
        for (final (client, cents) in invoices[d] ?? const <(String, int)>[]) {
          add('EOP', d, 'DI', 'Dépôt direct / $client', cents);
        }
    }
    if (d.day == 15 && d.month % 3 == 0) {
      for (final t in p.taxInstallments) {
        add('EOP', d, 'PWW', 'Paiement facture - AccèsD Internet / ${t.payee}', -t.cents);
      }
    }
    if (d.day == 1) add('EOP', d, 'VMW', 'Virement envoyé à / ${p.landlord} /Loyer', -_priceOn(p.rent, d));
    if (d.day == 2 && p.toSavings > 0) {
      add('EOP', d, 'VIW', 'Virement - AccèsD Internet / à ET 1', -p.toSavings);
      add('ET 1', d, 'VIW', 'Virement - AccèsD Internet / de EOP', p.toSavings);
    }
    if (d.day == 3 && p.tfsaOpened != null && !d.isBefore(p.tfsaOpened!)) {
      add('EOP', d, 'VIW', 'Virement - AccèsD Internet / à ET 2', -p.toTfsa);
      add('ET 2', d, 'VIW', 'Virement - AccèsD Internet / de EOP', p.toTfsa);
    }
    if (d.day == 25 && p.insurer != null) {
      add('EOP', d, 'RA', 'Prélèvement / ${p.insurer}', -_priceOn(p.insurance, d));
    }
    if (d.day == 10 && d.month.isOdd && p.utility != null) {
      // Bimonthly electricity bill, about twice as high in winter.
      final winter = d.month <= 3 || d.month >= 11;
      add(
        'EOP',
        d,
        'PWW',
        'Paiement facture - AccèsD Internet / ${p.utility}',
        -dice.around(winter ? 21000 : 9500, .12),
      );
    }
    for (final e in cardPayments) {
      if (e.date == d) add(e.account, d, e.code, e.description, e.amount);
    }
    if (d == nextAtm) {
      add('EOP', d, 'IRGA', 'Retrait au GA / ${p.atmCaisse}', -dice.pick([4000, 6000, 8000, 10000]));
      nextAtm = _day(d, dice.range(30, 50));
    }
    if (weekday == DateTime.saturday && p.friends.isNotEmpty && dice.chance(.35)) {
      final friend = dice.pick(p.friends);
      if (dice.chance(.55)) {
        add('EOP', d, 'VMW', 'Virement Interac à / $friend/', -dice.around(3500, .5));
      } else {
        add('EOP', d, 'VMW', 'Virement Interac de / $friend/', dice.around(2800, .5));
      }
    }
    // Tax refunds in May, a cancelled transfer.
    if (p.taxRefund && d.month == 5 && d.day == 8) {
      add('EOP', d, 'DI', 'Dépôt direct / Remboursement impôt Québec', dice.around(64000, .2));
    }
    if (d == p.cancelledTransfer) {
      add('EOP', d, 'VMW', 'Virement Interac à / ${p.friends.first}/', -4000);
      add('EOP', d, 'VMW', 'Annulation - Virement Interac à / ${p.friends.first}/', 4000);
    }
    if (_day(d, 1).day == 1) {
      final excess = p.sweepAbove == null ? 0 : balance['EOP']! - p.sweepAbove!;
      if (excess > 0) {
        add('EOP', d, 'VIW', 'Virement - AccèsD Internet / à ET 1', -excess);
        add('ET 1', d, 'VIW', 'Virement - AccèsD Internet / de EOP', excess);
      }
      add('EOP', d, 'FIX', "Frais fixes d'utilisation", -395);
      final savings = ((balance['ET 1'] ?? 0) * p.savingsRate / 12).round();
      if (savings > 0) add('ET 1', d, 'IET', 'Intérêt sur ET', savings);
      final tfsa = ((balance['ET 2'] ?? 0) * p.tfsaRate / 12).round();
      if (tfsa > 0) add('ET 2', d, 'IET', 'Intérêt sur ET', tfsa);
    }
  }
  return out;
}
