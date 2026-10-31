import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:banks/desjardins.dart';
import 'package:pdf_words/pdf_words.dart';
import 'package:test/test.dart';

ImportedStatement load(String name) => toImported(
  parseStatement(
    DocumentWords.fromJson(
      jsonDecode(File('test/fixtures/desjardins/$name').readAsStringSync()) as Map<String, dynamic>,
    ),
  ),
);

void main() {
  test('account statement: accounts and kinds from Desjardins codes', () {
    final s = load('desjardins-account-2026-09.synthetic.json');
    expect(s.isValid, isTrue);
    expect(s.accounts.map((a) => (a.ref, a.type)), [
      ('EOP', AccountType.checking),
      ('ET 1', AccountType.savings),
      ('CS', AccountType.share),
      ('ET 2', AccountType.registered),
    ]);
    expect(s.accounts.first.closingBalance, 890170);
    ImportedLine byCode(String code) => s.lines.firstWhere((l) => l.code == code);
    final cardPayment = s.lines.singleWhere((l) => l.code == 'PWW' && l.description.contains('Mastercard'));
    expect((cardPayment.kind, cardPayment.categoryHint), (TransactionKind.transfer, 'excluded.card_payment'));
    final bill = s.lines.singleWhere((l) => l.code == 'PWW' && l.description.contains('Hydro'));
    expect((bill.kind, bill.merchantText), (TransactionKind.expense, 'Hydro-Québec'));
    expect(byCode('IRGA').categoryHint, 'excluded.cash_withdrawal');
    expect(byCode('FIX').kind, TransactionKind.fee);
    expect(byCode('IET').kind, TransactionKind.interest);
    final rent = s.lines.singleWhere((l) => l.description.contains('/Loyer'));
    expect(
      (rent.kind, rent.categoryHint, rent.merchantText),
      (TransactionKind.expense, 'housing.rent', 'Martin Lavoie'),
    );
    final sent = s.lines.firstWhere((l) => l.code == 'VMW' && l.amount < 0 && !l.description.contains('Loyer'));
    expect((sent.kind, sent.isPerson), (TransactionKind.expense, true));
    expect(sent.merchantText, isIn(['JULIE TREMBLAY', 'MARC GAGNON', 'SOPHIE ROY']));
    expect(s.lines.firstWhere((l) => l.code == 'RA').merchantText, 'ASSURANCES BOREALE');
  });

  test('older account codes: transfers between own accounts, ATM, deposits, interest, Interac received', () {
    final section = AccountSection(id: 'EOP', name: 'Compte', opening: 0);
    for (final (code, description, amount) in [
      ('VIM', 'Virement manuel', -10000),
      ('VIR', 'Virement automatique au compte CS', -500),
      ('OUV', 'Ouverture de compte', 10000),
      ('IDGA', 'Dépôt au GA / CPD X', 2000),
      ('RGA', 'Retrait au GA / X', -40000),
      ('RGP', 'Retrait à un GA / X', -10000),
      ('ADM', 'Frais au GA Interac/Plus', -150),
      ('INT', 'Intérêt sur EOP', 3),
      ('BNI', 'Boni', 186),
      ('DMD', 'Dépôt Mobile', 50000),
      ('RIS', 'Ristourne', 7000),
      ('IVMW', 'Virement reçu de / PERSONNE01 /Rbsm', 2500),
    ]) {
      section.lines.add(
        AccountLine(date: DateTime.utc(2022, 3, 1), code: code, description: description)
          ..withdrawal = amount < 0 ? -amount : 0
          ..deposit = amount > 0 ? amount : 0,
      );
    }
    final s = toImported(
      AccountStatement(periodStart: DateTime.utc(2022, 3), periodEnd: DateTime.utc(2022, 3, 31), sections: [section]),
    );
    final byCode = {for (final l in s.lines) l.code: l};
    for (final code in ['VIM', 'VIR', 'OUV', 'IDGA']) {
      expect(
        (byCode[code]!.kind, byCode[code]!.categoryHint),
        (TransactionKind.transfer, 'excluded.internal_transfer'),
      );
    }
    for (final code in ['RGA', 'RGP']) {
      expect((byCode[code]!.kind, byCode[code]!.categoryHint), (TransactionKind.transfer, 'excluded.cash_withdrawal'));
    }
    expect(byCode['ADM']!.kind, TransactionKind.fee);
    expect([byCode['INT']!.kind, byCode['BNI']!.kind], [TransactionKind.interest, TransactionKind.interest]);
    expect([byCode['DMD']!.kind, byCode['RIS']!.kind], [TransactionKind.income, TransactionKind.income]);
    final interac = byCode['IVMW']!;
    expect((interac.kind, interac.isPerson, interac.merchantText), (TransactionKind.income, true, 'PERSONNE01'));
  });

  test('card statements: purchases, refunds, payment, rewards, fee', () {
    final s = load('desjardins-card-2026-02.synthetic.json');
    expect(s.accounts.single.ref, 'card-0001');
    expect(s.accounts.single.closingBalance, lessThan(0));
    final kinds = {for (final l in s.lines) l.kind};
    expect(
      kinds,
      containsAll([TransactionKind.expense, TransactionKind.refund, TransactionKind.transfer, TransactionKind.fee]),
    );
    expect(s.lines.singleWhere((l) => l.description == 'FRAIS ANNUELS').categoryHint, 'finance.bank_fees');
    expect(s.lines.singleWhere((l) => l.description.startsWith('PAIEMENT')).kind, TransactionKind.transfer);
    final january = load('desjardins-card-2026-01.synthetic.json');
    expect(january.lines.singleWhere((l) => l.description.contains('BONIDOLLARS')).categoryHint, 'income.rewards');
  });
}
