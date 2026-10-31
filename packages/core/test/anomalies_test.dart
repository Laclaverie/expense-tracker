import 'package:core/core.dart';
import 'package:test/test.dart';

SpendLine line(
  DateTime date,
  int cents,
  int merchantId,
  String merchant, {
  String? category,
  bool person = false,
  int account = 1,
  bool ok = false,
}) => SpendLine(
  date: date,
  cents: cents,
  merchantId: merchantId,
  merchant: merchant,
  categoryId: category,
  isPerson: person,
  accountId: account,
  anomalyOk: ok,
);

/// A year of ordinary shopping (100 lines, 20-70 $) so "very large" has a reference.
final ordinary = [
  for (var i = 0; i < 100; i++)
    line(
      DateTime.utc(2025, 11, 1).add(Duration(days: i * 3)),
      2000 + (i % 6) * 1000,
      100 + i % 5,
      'DEMO SHOP ${i % 5}',
    ),
];

void main() {
  final end = DateTime.utc(2026, 10, 20);

  test('a big run at a shop without regular amounts is not reported', () {
    final lines = [
      ...ordinary,
      for (var i = 0; i < 6; i++) line(DateTime.utc(2026, 4 + i, 3), 4000 + i * 700, 1, 'ACME MARCHE'),
      line(DateTime.utc(2026, 10, 12), 23900, 1, 'ACME MARCHE'),
    ];
    expect(detectAnomalies(lines, asOf: end), isEmpty);
  });

  test('a very large expense is reported wherever it is, people left out', () {
    final lines = [
      ...ordinary,
      line(DateTime.utc(2026, 10, 15), 76800, 2, 'ACME GARAGE'),
      line(DateTime.utc(2026, 10, 16), 90000, 3, 'PERSONNE01', person: true),
    ];
    final found = detectAnomalies(lines, asOf: end);
    expect(found.map((a) => (a.kind, a.merchant, a.cents)), [(AnomalyKind.highAmount, 'ACME GARAGE', 76800)]);
  });

  test('without enough history, nothing is "very large"', () {
    expect(detectAnomalies([line(DateTime.utc(2026, 10, 15), 76800, 2, 'ACME GARAGE')], asOf: end), isEmpty);
  });

  test('a regular bill at a different amount is reported; back to normal is not', () {
    final lines = [
      for (var m = 1; m <= 8; m++) line(DateTime.utc(2026, m, 14), 2248, 9, 'ACME MOBILE'),
      line(DateTime.utc(2026, 9, 14), 4748, 9, 'ACME MOBILE'),
      line(DateTime.utc(2026, 10, 14), 2248, 9, 'ACME MOBILE'),
    ];
    final found = detectAnomalies(lines, asOf: end);
    expect(found.map((a) => (a.kind, a.date, a.cents, a.usual)), [
      (AnomalyKind.regularAmount, DateTime.utc(2026, 9, 14), 4748, 2248),
    ]);
  });

  test('two regular amounts at one merchant (two policies) are both normal', () {
    final lines = [
      for (var m = 1; m <= 10; m++) line(DateTime.utc(2026, m, 3), 8131, 12, 'ACME ASSURANCES'),
      for (var m = 1; m <= 10; m++) line(DateTime.utc(2026, m, 23), 3180, 12, 'ACME ASSURANCES'),
    ];
    expect(detectAnomalies(lines, asOf: end), isEmpty);
    final oneOff = [...lines, line(DateTime.utc(2026, 10, 12), 15000, 12, 'ACME ASSURANCES')];
    expect(detectAnomalies(oneOff, asOf: end).map((a) => (a.kind, a.cents, a.usual)), [
      (AnomalyKind.regularAmount, 15000, 8131),
    ]);
  });

  test('a payment marked normal is no longer reported, and not missing either', () {
    final lines = [
      for (var m = 1; m <= 8; m++) line(DateTime.utc(2026, m, 14), 2248, 9, 'ACME MOBILE'),
      line(DateTime.utc(2026, 9, 14), 4748, 9, 'ACME MOBILE', ok: true),
      line(DateTime.utc(2026, 10, 15), 1500, 11, 'DEMO CAFE'),
    ];
    expect(detectAnomalies(lines, asOf: end), isEmpty);
    final big = [...ordinary, line(DateTime.utc(2026, 10, 15), 76800, 2, 'ACME GARAGE', ok: true)];
    expect(detectAnomalies(big, asOf: end), isEmpty);
  });

  test('a missing payment says how late it is and until when the account was seen', () {
    final rent = [for (var m = 1; m <= 9; m++) line(DateTime.utc(2026, m, 1), 120000, 10, 'PERSONNE02', person: true)];
    final a = detectAnomalies([...rent, line(DateTime.utc(2026, 10, 18), 1500, 11, 'DEMO CAFE')], asOf: end).single;
    expect((a.toleranceDays, a.seenUntil), (6, DateTime.utc(2026, 10, 18)));
  });

  test('a subscription price change is reported with the old price', () {
    final lines = [
      for (var m = 1; m <= 9; m++) line(DateTime.utc(2026, m, 5), 1494, 7, 'ACME STREAMING'),
      line(DateTime.utc(2026, 10, 5), 1699, 7, 'ACME STREAMING'),
    ];
    expect(detectAnomalies(lines, asOf: end).map((a) => (a.kind, a.cents, a.usual)), [
      (AnomalyKind.regularAmount, 1699, 1494),
    ]);
  });

  test('a varying regular expense (fuel) is never reported for its amount', () {
    final fuel = [
      for (var w = 0; w < 30; w++)
        line(DateTime.utc(2026, 3, 1).add(Duration(days: 7 * w)), 5000 + (w % 3) * 600, 8, 'DEMO ESSENCE'),
    ];
    expect(detectAnomalies(fuel, asOf: end), isEmpty);
  });

  test('a missing regular payment is reported once its account shows later lines', () {
    final rent = [for (var m = 1; m <= 9; m++) line(DateTime.utc(2026, m, 1), 120000, 10, 'PERSONNE02', person: true)];
    final laterOnAccount = [line(DateTime.utc(2026, 10, 18), 1500, 11, 'DEMO CAFE')];
    final found = detectAnomalies([...rent, ...laterOnAccount], asOf: end);
    expect(found.map((a) => (a.kind, a.merchant, a.date)), [
      (AnomalyKind.regularMissing, 'PERSONNE02', DateTime.utc(2026, 10, 1)),
    ]);

    // Paid from another account whose statement isn't imported that far yet: not missing.
    final otherAccount = [line(DateTime.utc(2026, 9, 3), 1500, 11, 'DEMO CAFE', account: 1)];
    final rent2 = [for (final l in rent) line(l.date, l.cents, 10, 'PERSONNE02', person: true, account: 2)];
    expect(
      detectAnomalies([
        ...rent2,
        ...otherAccount,
        line(DateTime.utc(2026, 10, 2), 100, 12, 'X', account: 2),
      ], asOf: end),
      isEmpty,
    );
  });

  test('a fee from a new source is reported once', () {
    final lines = [
      line(DateTime.utc(2026, 10, 1), 750, 6, 'FRAIS EFFET RETOURNE', category: 'finance.bank_fees'),
      line(DateTime.utc(2026, 10, 15), 750, 6, 'FRAIS EFFET RETOURNE', category: 'finance.bank_fees'),
    ];
    expect(detectAnomalies(lines, asOf: end).map((a) => (a.kind, a.date)), [
      (AnomalyKind.newFee, DateTime.utc(2026, 10, 1)),
    ]);
  });

  group('regularOutliers (whole history, no alert)', () {
    test('every spike of a regular bill, old or recent, with the usual amount at the time', () {
      final lines = [
        for (var m = 1; m <= 10; m++)
          line(DateTime.utc(2026, m, 14), m == 5 ? 5928 : (m == 9 ? 4748 : 2248), 9, 'ACME MOBILE'),
      ];
      final found = regularOutliers(lines)[9]!;
      expect(found.map((o) => (o.date, o.cents, o.usual)), [
        (DateTime.utc(2026, 5, 14), 5928, 2248),
        (DateTime.utc(2026, 9, 14), 4748, 2248),
      ]);
      // Only the recent one is an alert.
      expect(detectAnomalies(lines, asOf: end).map((a) => a.date), [DateTime.utc(2026, 9, 14)]);
    });

    test('after a price change only the first payment at the new price stands out', () {
      final lines = [
        for (var m = 1; m <= 5; m++) line(DateTime.utc(2025, m, 5), 1299, 7, 'ACME STREAMING'),
        for (var m = 6; m <= 12; m++) line(DateTime.utc(2025, m, 5), 1494, 7, 'ACME STREAMING'),
      ];
      expect(regularOutliers(lines)[7]!.map((o) => (o.date, o.cents, o.usual)), [
        (DateTime.utc(2025, 6, 5), 1494, 1299),
      ]);
    });

    test('a payment marked normal is listed as such and does not move the usual amount', () {
      final lines = [
        for (var m = 1; m <= 8; m++) line(DateTime.utc(2026, m, 14), 2248, 9, 'ACME MOBILE'),
        line(DateTime.utc(2026, 9, 14), 4748, 9, 'ACME MOBILE', ok: true),
        line(DateTime.utc(2026, 10, 14), 4748, 9, 'ACME MOBILE'),
      ];
      final found = regularOutliers(lines)[9]!;
      expect(found.map((o) => (o.date, o.ok)), [
        (DateTime.utc(2026, 9, 14), true),
        (DateTime.utc(2026, 10, 14), false),
      ]);
    });

    test('irregular amounts (fuel) are not a regular bill', () {
      final fuel = [
        for (var w = 0; w < 30; w++)
          line(
            DateTime.utc(2026, 3, 1).add(Duration(days: 7 * w)),
            3000 + (w * 1777 + w * w * 313) % 4000,
            8,
            'DEMO ESSENCE',
          ),
      ];
      expect(regularOutliers(fuel)[8], isNull);
    });
  });
}
