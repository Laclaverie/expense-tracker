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

  test('day range wraps over the month end', () {
    final lines = [
      for (final d in ['2026-01-30', '2026-03-02', '2026-03-31', '2026-05-01', '2026-05-29']) pay(1, 'Gym', d, 4000),
    ];
    final r = detectRecurring(lines).single;
    expect((r.dayRange, r.fixedDate), ((29, 2), false));
  });
}
