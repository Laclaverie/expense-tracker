import 'package:core/core.dart';
import 'package:test/test.dart';

ImportedLine line(String description, {String? code, int? bonusRate, String? hint}) => ImportedLine(
  accountRef: 'card-0001',
  date: DateTime.utc(2026, 9, 1),
  amount: -1000,
  description: description,
  kind: TransactionKind.expense,
  merchantText: description,
  code: code,
  bonusRate: bonusRate,
  categoryHint: hint,
);

void main() {
  group('normalizeMerchant', () {
    final cases = {
      'TIM HORTONS #8517': ('TIM HORTONS', 'Tim Hortons'),
      'COSTCO WHOLESALE W515': ('COSTCO', 'Costco'),
      'COSTCO ESSENCE W1446': ('COSTCO ESSENCE', 'Costco Essence'),
      'SQ *FERME AUX MILLE CA': ('FERME AUX MILLE CA', 'Ferme Aux Mille Ca'),
      'GOOGLE *YouTube': ('YOUTUBE', 'YouTube'),
      'Patreon* Membership': ('PATREON', 'Patreon'),
      'Lyft *Temp Auth Hold': ('LYFT', 'Lyft'),
      'AIRBNB * XXXXXX9XXX': ('AIRBNB', 'Airbnb'),
      'AIR CAN* 9999999999999': ('AIR CANADA', 'Air Canada'),
      'BKG*HOTEL AT BOOKING.C': ('BOOKING.COM', 'Booking.com'),
      'SAQ23185 ATELIERS ANGU': ('SAQ', 'SAQ'),
      'SHELL C03028': ('SHELL', 'Shell'),
      'IGA 8253': ('IGA', 'IGA'),
      "T'AMI RESTAURANT": ("T'AMI RESTAURANT", "T'ami Restaurant"),
      'CAFÉ LE FALCO': ('CAFE LE FALCO', 'Café Le Falco'),
      'Intérêt sur ET': ('INTERET SUR ET', 'Intérêt Sur Et'),
    };
    for (final MapEntry(key: raw, value: (key, display)) in cases.entries) {
      test(raw, () {
        final m = normalizeMerchant(raw);
        expect((m.key, m.display), (key, display));
      });
    }
  });

  group('Categorizer', () {
    test('order: rule > remembered merchant > bank hint > seed > keyword > Bonidollars', () {
      final tim = normalizeMerchant('TIM HORTONS #1');
      expect(Categorizer().categorize(line('TIM HORTONS #1'), tim).categoryId, 'food.coffee');
      expect(
        Categorizer(merchantCategories: {'TIM HORTONS': 'food.restaurants'}).categorize(line('TIM HORTONS #1'), tim),
        isA<CategorySuggestion>().having((s) => s.confidence, 'confidence', Confidence.merchant),
      );
      final ruled = Categorizer(
        rules: [const Rule(id: 1, categoryId: 'leisure.outings', descriptionContains: 'tim hor')],
        merchantCategories: {'TIM HORTONS': 'food.restaurants'},
      ).categorize(line('TIM HORTONS #1'), tim);
      expect((ruled.categoryId, ruled.confidence), ('leisure.outings', Confidence.rule));

      final fee = line('Frais fixes', code: 'FIX', hint: 'finance.bank_fees');
      expect(Categorizer().categorize(fee, normalizeMerchant('Frais fixes')).confidence, Confidence.bank);

      final bistro = line('LE PETIT BISTRO MONTREAL');
      expect(Categorizer().categorize(bistro, normalizeMerchant(bistro.description)).categoryId, 'food.restaurants');

      final unknown = line('ZZZ UNKNOWN', bonusRate: 300);
      final s = Categorizer().categorize(unknown, normalizeMerchant(unknown.description));
      expect((s.categoryId, s.needsReview), ('food', true));
    });
  });

  test('matchTransfers pairs opposite amounts on different accounts, closest date first', () {
    final d = DateTime.utc(2026, 9, 1);
    final pairs = matchTransfers([
      TransferCandidate('pay', 1, -294864, d),
      TransferCandidate('far', 2, 294864, d.add(const Duration(days: 4))),
      TransferCandidate('near', 2, 294864, d.add(const Duration(days: 1))),
      TransferCandidate('same-account', 1, 294864, d),
      TransferCandidate('too-late', 3, 1000, d.add(const Duration(days: 20))),
      TransferCandidate('out', 1, -1000, d),
    ]);
    expect(pairs.map((p) => (p.$1.id, p.$2.id)), [('pay', 'near')]);
  });

  test('fingerprints distinguish identical lines by occurrence', () {
    final d = DateTime.utc(2026, 9, 14);
    final occ = occurrences([('a', d, -500, 'BAR'), ('a', d, -500, 'BAR'), ('a', d, -700, 'BAR')]);
    expect(occ, [0, 1, 0]);
    String fp(int o) => lineFingerprint(
      institution: 'desjardins',
      accountRef: 'a',
      date: d,
      amount: -500,
      description: 'BAR',
      occurrence: o,
    );
    expect(fp(0), isNot(fp(1)));
    expect(fp(0), fp(0));
  });

  test('every category belongs to an existing group', () {
    final ids = {for (final c in defaultCategories) c.id};
    expect(defaultCategories.where((c) => c.parentId != null && !ids.contains(c.parentId)), isEmpty);
    expect(seedMerchantCategories.values.where((c) => !ids.contains(c)), isEmpty);
    expect(keywordCategories.map((k) => k.$2).where((c) => !ids.contains(c)), isEmpty);
  });

  test('formatMoney', () {
    expect(formatMoney(-123456, 'CAD'), '-1 234,56 \$');
    expect(formatMoney(-123456, 'CAD', languageCode: 'en'), '-\$1,234.56');
    expect(formatMoney(500, 'EUR'), '5,00 €');
  });
}
