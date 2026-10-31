import 'dart:convert';
import 'dart:io';

import 'package:banks/desjardins.dart';
import 'package:pdf_words/pdf_words.dart';
import 'package:test/test.dart';

/// Synthetic statements of a made-up household (`dart run demo:fixtures`).
final fixtures = Directory('test/fixtures/desjardins')
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('.synthetic.json'));

DocumentWords load(String name) => DocumentWords.fromJson(
  jsonDecode(File('test/fixtures/desjardins/$name').readAsStringSync()) as Map<String, dynamic>,
);

void main() {
  group('every fixture parses and validates', () {
    for (final f in fixtures) {
      final name = f.uri.pathSegments.last;
      test(name, () {
        final s = parseStatement(load(name));
        expect(s.checks.where((c) => !c.ok), isEmpty);
        expect(s, name.startsWith('desjardins-card') ? isA<CardStatement>() : isA<AccountStatement>());
      });
    }
  });

  group('account statement 2026-09', () {
    final s = parseAccountStatement(load('desjardins-account-2026-09.synthetic.json'));

    test('period and sections', () {
      expect(s.periodStart, DateTime.utc(2026, 9, 1));
      expect(s.periodEnd, DateTime.utc(2026, 9, 30));
      expect(s.sections.map((x) => x.id), ['EOP', 'ET 1', 'CS', 'ET 2']);
    });

    test('checking account lines and balances', () {
      final eop = s.section('EOP')!;
      expect(eop.opening, 879703);
      expect(eop.lines, hasLength(13));
      expect(eop.closing, 890170);
      final first = eop.lines.first;
      expect((first.date, first.code, first.amount), (DateTime.utc(2026, 9, 1), 'VMW', -149500));
    });

    test('wrapped description is joined, page header is not', () {
      final eop = s.section('EOP')!;
      final payment = eop.lines.singleWhere((l) => l.code == 'PWW' && l.description.contains('Mastercard'));
      expect(payment.description, endsWith('Odyssée World Elite Mastercard'));
      expect(payment.amount, -131840);
      expect(s.section('ET 1')!.lines.last.description, 'Intérêt sur ET');
    });

    test('cancellation, ATM and fee lines', () {
      final eop = s.section('EOP')!;
      expect(eop.lines.singleWhere((l) => l.description.startsWith('Annulation')).amount, 4000);
      expect(eop.lines.singleWhere((l) => l.code == 'IRGA').amount, -4000);
      expect(eop.lines.singleWhere((l) => l.code == 'FIX').amount, -395);
    });
  });

  group('card statement', () {
    test('lines carry dates, location, Bonidollars rate, foreign amount', () {
      final s = parseCardStatement(load('desjardins-card-2026-09.synthetic.json'));
      expect(s.statementDate, DateTime.utc(2026, 9, 20));
      final first = s.lines.first;
      expect(first.transactionDate, DateTime.utc(2026, 8, 20));
      expect(first.postedDate, DateTime.utc(2026, 8, 21));
      expect(first.location, 'TORONTO ON');
      expect(first.bonusRate, 200);
      expect(first.amount, -3535);
      final usd = parseCardStatement(load('desjardins-card-2026-05.synthetic.json')).lines
          .where((l) => l.foreign != null)
          .first;
      expect(
        (usd.amount, usd.foreign!.cents, usd.foreign!.currency, usd.foreign!.rate),
        (-1783, 1300, 'USD', '1.371200'),
      );
    });

    test('December payment on a January statement belongs to the previous year', () {
      final s = parseCardStatement(load('desjardins-card-2026-01.synthetic.json'));
      final payment = s.lines.singleWhere((l) => l.description == 'PAIEMENT CAISSE');
      expect(payment.transactionDate, DateTime.utc(2025, 12, 24));
      expect(payment.isCredit, isTrue);
      expect(payment.section, CardSection.operations);
    });

    test('several cards, refund inside purchases, annual fee in operations', () {
      final s = parseCardStatement(load('desjardins-card-2026-02.synthetic.json'));
      expect(s.cardTotals, hasLength(2));
      final refund = s.lines.singleWhere((l) => l.isCredit && l.section == CardSection.purchases);
      expect(refund.amount, 4799);
      final fee = s.lines.singleWhere((l) => l.description == 'FRAIS ANNUELS');
      expect((fee.amount, fee.section, fee.isCredit), (-13000, CardSection.operations, false));
    });
  });

  group('card statement, October 2026 layout', () {
    final s = parseCardStatement2026(load('desjardins-card-2026-10.synthetic.json'));

    test('is detected as a card statement of the same account as older layouts', () {
      expect(cardLayout(load('desjardins-card-2026-10.synthetic.json'))?.name, '2026-10');
      expect(cardLayout(load('desjardins-card-2026-09.synthetic.json'))?.name, 'original');
      expect(s.accountNumber, parseCardStatement(load('desjardins-card-2026-09.synthetic.json')).accountNumber);
    });

    test('full dates, merchant and location split, no Bonidollars rate', () {
      expect(s.statementDate, DateTime.utc(2026, 10, 20));
      final first = s.lines.first;
      expect((first.transactionDate, first.postedDate), (DateTime.utc(2026, 9, 20), DateTime.utc(2026, 9, 22)));
      expect((first.description, first.location, first.amount), ('IGA EXTRA #8123', 'MONTREAL QC', -6125));
      expect(first.bonusRate, isNull);
      // No region code: the name's padding sets the location apart.
      expect(s.lines.firstWhere((l) => l.description == 'SPOTIFY').location, 'Internet');
    });

    test('foreign amount on the two rows under the line', () {
      final usd = s.lines.singleWhere((l) => l.foreign != null);
      expect(
        (usd.amount, usd.foreign!.cents, usd.foreign!.currency, usd.foreign!.rate),
        (-3473, 2500, 'USD', '1.38910000'),
      );
    });

    test('summary, card total and payment in operations', () {
      expect(s.summary['payments'], 131840);
      expect(s.summary['newBalance'], 278244);
      expect(s.cardTotals.values.fold(0, (a, b) => a + b), 278244);
      final payment = s.lines.singleWhere((l) => l.section == CardSection.operations);
      expect((payment.description, payment.amount, payment.isCredit), ('PAIEMENT CAISSE', 131840, true));
    });

    test('a tampered amount is caught by validation', () {
      final doc = load('desjardins-card-2026-10.synthetic.json');
      final page = doc.pages[1];
      final i = page.words.indexWhere((w) => w.text == '61,25');
      page.words[i] = page.words[i].withText('61,26');
      expect(parseCardStatement2026(doc).isValid, isFalse);
    });
  });

  group('splitMerchant', () {
    (String, String) split(String text) {
      var x = 0.0;
      final words = [
        for (final t in text.split(' '))
          if (t.isNotEmpty) Word(t, x, x += t.length * 5, 100),
      ];
      return splitMerchant(words);
    }

    test('one-word city, or two after a prefix or before a suffix', () {
      expect(split('ACME CORP #12 MONTREAL QC'), ('ACME CORP #12', 'MONTREAL QC'));
      expect(split('ACME CORP SAINT LEONARD QC'), ('ACME CORP', 'SAINT LEONARD QC'));
      expect(split('ACME 123 AULDS COVE NS'), ('ACME 123', 'AULDS COVE NS'));
    });

    test('a name cut at 22 characters ends where the city starts', () {
      expect(split('ACME CORPORATION LIMIT NORTH RUSTIC PE'), ('ACME CORPORATION LIMIT', 'NORTH RUSTIC PE'));
      expect(split('ACME CORPORATI #9 SAINT LEONARD QC'), ('ACME CORPORATI #9', 'SAINT LEONARD QC'));
    });

    test('without a region code, a wide gap or nothing', () {
      expect(split('ACME SHOP'), ('ACME SHOP', ''));
      final gap = [Word('ACME', 0, 20, 100), Word('Membership', 22, 70, 100), Word('Internet', 85, 120, 100)];
      expect(splitMerchant(gap), ('ACME Membership', 'Internet'));
    });
  });

  test('a tampered amount is caught by validation', () {
    final doc = load('desjardins-card-2026-09.synthetic.json');
    final page = doc.pages.first;
    final i = page.words.indexWhere((w) => w.text == '35,35');
    page.words[i] = page.words[i].withText('35,53');
    final s = parseCardStatement(doc);
    expect(s.isValid, isFalse);
    expect(s.checks.where((c) => !c.ok).map((c) => c.name), contains('debits = Achats / débits'));
  });
}
