import 'package:core/core.dart';
import 'package:test/test.dart';

SpendLine pay(int id, String name, String date, int cents, {String? cat, bool person = false}) => SpendLine(
  date: DateTime.parse('${date}T00:00:00Z'),
  cents: cents,
  categoryId: cat,
  merchantId: id,
  merchant: name,
  isPerson: person,
);

void main() {
  test('phone bill paid by hand: date drifts, some months cost more', () {
    final lines = [
      for (final (d, c) in [
        ('2026-01-13', 2248),
        ('2026-02-12', 2248),
        ('2026-03-15', 2248),
        ('2026-04-13', 2248),
        ('2026-05-15', 5928),
        ('2026-06-13', 2248),
        ('2026-07-18', 2248),
        ('2026-08-13', 2248),
        ('2026-09-13', 4748),
      ])
        pay(1, 'Phone', d, c, cat: 'telecom.mobile'),
    ];
    final r = detectRecurring(lines).single;
    expect((r.merchant, r.cadence, r.payments.length), ('Phone', Cadence.monthly, 9));
    expect((r.typicalAmount, r.minAmount, r.maxAmount, r.monthlyCost), (2248, 2248, 5928, 2248));
    expect(r.fixedDate, isFalse);
    expect(r.dayRange, (12, 18));
    expect(r.nextExpected, DateTime.utc(2026, 10, 13));
    expect((r.active, r.categoryId), (true, 'telecom.mobile'));
  });

  test('automatic debit on a fixed day; price change; missing statements', () {
    final lines = [
      for (final (d, c) in [
        ('2026-01-27', 500),
        ('2026-02-27', 500),
        ('2026-03-27', 500),
        // No statement for April–May.
        ('2026-06-27', 862),
        ('2026-07-27', 862),
        ('2026-08-27', 862),
      ])
        pay(1, 'Creator', d, c),
    ];
    final r = detectRecurring(lines, asOf: DateTime.utc(2026, 9, 30)).single;
    expect((r.cadence, r.payments.length, r.typicalAmount, r.fixedDate), (Cadence.monthly, 6, 862, true));
  });

  test('two series at one merchant, split by amount; stray payments left out', () {
    final lines = [
      for (final (d, c) in [
        ('2026-04-01', 8131),
        ('2026-04-23', 3180),
        ('2026-05-01', 1),
        ('2026-05-05', 1000),
        ('2026-05-18', 8131),
        ('2026-05-25', 3180),
        ('2026-07-01', 8131),
        ('2026-07-23', 3180),
        ('2026-08-03', 8131),
        ('2026-08-24', 3180),
        ('2026-09-01', 8131),
        ('2026-09-23', 3180),
      ])
        pay(1, 'Insurer', d, c),
    ];
    final found = detectRecurring(lines);
    expect(found.map((r) => r.typicalAmount), [8131, 3180]);
    expect(found.every((r) => r.cadence == Cadence.monthly), isTrue);
    expect(found.last.payments.length, 5);
  });

  test('irregular shopping is not recurring', () {
    final lines = [
      for (final (d, c) in [
        ('2025-12-23', 17734),
        ('2025-12-26', 8183),
        ('2026-01-04', 9731),
        ('2026-01-25', 19256),
        ('2026-02-15', 116127),
        ('2026-03-08', 9041),
        ('2026-03-24', 24879),
        ('2026-05-17', 36327),
        ('2026-06-06', 21999),
        ('2026-06-20', 9908),
        ('2026-07-18', 23519),
        ('2026-08-30', 19006),
      ])
        pay(1, 'Warehouse', d, c),
      pay(2, 'Coins', '2026-02-23', 24995),
      pay(2, 'Coins', '2026-05-21', 24995),
      pay(2, 'Coins', '2026-06-25', 24995),
    ];
    expect(detectRecurring(lines), isEmpty);
  });

  test('same-day lines merge, refunds ignored, rent to a person, weekly', () {
    final lines = [
      for (final d in ['2026-06-30', '2026-07-31', '2026-08-31', '2026-09-29'])
        pay(1, 'Landlord', d, 145000, cat: 'housing.rent', person: true),
      for (var i = 0; i < 6; i++) ...[
        pay(2, 'Club', DateTime.utc(2026, 9, 1 + 7 * i).toIso8601String().substring(0, 10), 1500),
        if (i == 2) pay(2, 'Club', DateTime.utc(2026, 9, 15).toIso8601String().substring(0, 10), -1500),
      ],
      // Split transaction: two lines, one payment.
      pay(3, 'Stream', '2026-07-21', 1000),
      pay(3, 'Stream', '2026-07-21', 494),
      pay(3, 'Stream', '2026-08-21', 1494),
      pay(3, 'Stream', '2026-09-21', 1494),
    ];
    final found = {for (final r in detectRecurring(lines, asOf: DateTime.utc(2026, 10, 10))) r.merchant: r};
    expect(found['Landlord']!.isPerson, isTrue);
    expect(found['Landlord']!.dayRange, (29, 31));
    expect((found['Club']!.cadence, found['Club']!.payments.length), (Cadence.weekly, 6));
    expect(found['Club']!.monthlyCost, (1500 * 30.44 / 7).round());
    expect(found['Stream']!.payments.map((p) => p.$2), [1494, 1494, 1494]);
  });

  test('a series not seen for a while is no longer active; active ones first', () {
    final lines = [
      for (final m in [1, 2, 3, 4]) pay(1, 'Old', '2026-0$m-05', 999),
      for (final m in [6, 7, 8, 9]) pay(2, 'Cheap', '2026-0$m-10', 100),
    ];
    final found = detectRecurring(lines, asOf: DateTime.utc(2026, 9, 30));
    expect(found.map((r) => (r.merchant, r.active)), [('Cheap', true), ('Old', false)]);
  });

  test('judged against its own account: a later card statement does not stop rent', () {
    SpendLine on(int account, SpendLine l) => SpendLine(
      date: l.date,
      cents: l.cents,
      categoryId: l.categoryId,
      merchantId: l.merchantId,
      merchant: l.merchant,
      isPerson: l.isPerson,
      accountId: account,
    );
    final lines = [
      // Account statements end Sept 30; the card statement goes to Oct 20.
      for (final m in [6, 7, 8, 9]) on(1, pay(1, 'Landlord', '2026-0$m-01', 145000, person: true)),
      on(1, pay(9, 'Bakery', '2026-09-30', 500)),
      for (final m in [7, 8, 9]) on(2, pay(2, 'Stream', '2026-0$m-14', 1499)),
      on(2, pay(9, 'Bakery', '2026-10-20', 500)),
      // Paid by card, last seen in July: stopped.
      for (final m in [4, 5, 6, 7]) on(2, pay(3, 'Gym', '2026-0$m-03', 4000)),
    ];
    final found = {for (final r in detectRecurring(lines)) r.merchant: r.active};
    expect(found, {'Landlord': true, 'Stream': true, 'Gym': false});
  });

  test('yearly needs the whole merchant: two similar amounts a year apart at a grocery are chance', () {
    final lines = [
      pay(1, 'Bank', '2025-02-03', 13000),
      pay(1, 'Bank', '2026-02-03', 13000),
      for (final (i, d) in [
        '02-11',
        '02-14',
        '03-20',
        '05-02',
        '05-06',
        '05-28',
        '07-09',
        '08-30',
        '09-03',
        '11-17',
      ].indexed)
        pay(2, 'Grocery', '2025-$d', 6000 + 1731 * i),
      pay(2, 'Grocery', '2025-01-02', 4015),
      pay(2, 'Grocery', '2026-01-02', 4015),
    ];
    final found = detectRecurring(lines, asOf: DateTime.utc(2026, 3, 1));
    expect(found.map((r) => (r.merchant, r.cadence)), [('Bank', Cadence.yearly)]);
  });

  test('day range wraps over the month end', () {
    final lines = [
      for (final d in ['2026-01-30', '2026-03-02', '2026-03-31', '2026-05-01', '2026-05-29']) pay(1, 'Gym', d, 4000),
    ];
    final r = detectRecurring(lines).single;
    expect((r.dayRange, r.fixedDate), ((29, 2), false));
  });
}
