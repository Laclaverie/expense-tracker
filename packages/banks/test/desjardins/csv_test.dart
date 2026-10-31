import 'package:banks/desjardins.dart';
import 'package:banks/plugin.dart';
import 'package:test/test.dart';

/// Made-up account export: EOP then ET01, newest line first in each, same
/// layout as AccèsD (16 columns, `""` for empty fields).
const _account = '''
Caisse ACME,1234567,EOP,2026/10/05,00015,Virement envoyé à /PERSONNE09 /Loyer,"",900.00,"","","","","","",1088.66,"merci PERSONNE09"
Caisse ACME,1234567,EOP,2026/10/04,00014,Paiement facture - AccèsD Internet /Mastercard Desjardins,"",500.00,"","","","","","",1988.66,""
Caisse ACME,1234567,EOP,2026/10/03,00013,Virement - AccesD Internet /à 1234567-ET1,"",100.00,"","","","","","",2488.66,""
Caisse ACME,1234567,EOP,2026/10/03,00012,Achat /ACME CORP,"",12.34,"","","","","","",2588.66,""
Caisse ACME,1234567,EOP,2026/10/02,00011,Paie /ACME CORP,"","",2000.00,"","","","","",2601.00,""
Caisse ACME,1234567,EOP,2026/10/01,00010,Frais au GA Interac/Visa,"",4.00,"","","","","","",601.00,""
Caisse ACME,1234567,EOP,2026/10/01,00009,Retrait au GA /ACME 123,"",20.00,"","","","","","",605.00,""
Caisse ACME,1234567,ET01,2026/10/03,00003,Virement - AccesD Internet /de 1234567-EOP,"","",100.00,"","","","","",200.12,""
Caisse ACME,1234567,ET01,2026/10/01,00002,Intérêt sur ET,"","",0.12,"","","","","",100.12,""
Caisse ACME,1234567,ET01,2026/09/15,00001,Ouverture de compte,"","",100.00,"","","","","",100.00,""
''';

/// Made-up card export: merchant (25) + city (13) + province, purchases in
/// column 12, credits in column 13.
const _card = '''
Odyssee World Elite Mastercard **** 4321,"","",2026/10/05,00104,CREDIT REMISE EN ARGENT BONIDOLLARS   ,"","","","","","",3.21
Odyssee World Elite Mastercard **** 4321,"","",2026/10/04,00103,ACME  CORP               MONTREAL     QC ,"","","","","",45.67,""
Odyssee World Elite Mastercard **** 4321,"","",2026/10/03,00102,PAIEMENT CAISSE                          ,"","","","","","",500.00
Odyssee World Elite Mastercard **** 4321,"","",2026/10/02,00101,ACME, INC                MONTREAL     QC ,"","","","","","",5.00
Odyssee World Elite Mastercard **** 4321,"","",2026/10/01,00100,*ACME.COM                Internet        ,"","","","","",12.00,""
''';

TextInput _csv(String text) => TextInput('x.csv', text, fileType: 'csv');

void main() {
  const importer = DesjardinsImporter();

  test('detect: account and card exports, nothing else', () {
    expect(importer.detect(_csv(_account)), 'desjardins-account');
    expect(importer.detect(_csv(_card)), 'desjardins-card');
    expect(importer.detect(_csv('a,b,c')), isNull);
    expect(importer.detect(TextInput('x.txt', _account, fileType: 'txt')), isNull);
  });

  test('account export: accounts, oldest first, balances checked, kinds without warnings', () {
    final s = importer.read(_csv(_account));
    expect(s.failedChecks, isEmpty);
    expect(s.checkCount, 6 + 2);
    expect(s.warnings, isEmpty);
    expect(s.periodStart, DateTime.utc(2026, 9, 15));
    expect(s.periodEnd, DateTime.utc(2026, 10, 5));
    expect(
      [for (final a in s.accounts) (a.ref, a.type, a.closingBalance)],
      [('EOP', AccountType.checking, 108866), ('ET 1', AccountType.savings, 20012)],
    );
    final eop = s.lines.where((l) => l.accountRef == 'EOP').toList();
    expect(eop.first.description, 'Retrait au GA /ACME 123');
    expect(
      [for (final l in eop) (l.amount, l.kind, l.categoryHint, l.merchantText)],
      [
        (-2000, TransactionKind.transfer, 'excluded.cash_withdrawal', 'ACME 123'),
        (-400, TransactionKind.fee, 'finance.bank_fees', 'Frais au GA Interac/Visa'),
        (200000, TransactionKind.income, 'income.salary', 'ACME CORP'),
        (-1234, TransactionKind.expense, null, 'ACME CORP'),
        (-10000, TransactionKind.transfer, 'excluded.internal_transfer', 'à ET 1'),
        (-50000, TransactionKind.transfer, 'excluded.card_payment', 'Mastercard Desjardins'),
        (-90000, TransactionKind.expense, 'housing.rent', 'PERSONNE09'),
      ],
    );
    expect(eop.last.isPerson, isTrue);
    expect(s.lines.where((l) => l.accountRef == 'ET 1').map((l) => l.kind), [
      TransactionKind.transfer,
      TransactionKind.interest,
      TransactionKind.transfer,
    ]);
  });

  test('account export in the AccesD order (days oldest first, a day newest first) reads the same', () {
    final lines = _account.trim().split('\n');
    String key(String l) => '${l.split(',')[2]} ${l.split(',')[3]}';
    // Group by account and day, days ascending, lines of a day kept newest first.
    final days = <String, List<String>>{};
    for (final l in lines) {
      days.putIfAbsent(key(l), () => []).add(l);
    }
    final accesD = [
      for (final account in ['EOP', 'ET01'])
        for (final k in days.keys.where((k) => k.startsWith('$account ')).toList()..sort()) ...days[k]!,
    ].join('\n');
    final a = importer.read(_csv(accesD)), b = importer.read(_csv(_account));
    expect(a.failedChecks, isEmpty);
    expect([for (final l in a.lines) (l.date, l.amount)], [for (final l in b.lines) (l.date, l.amount)]);
  });

  test('account export: a wrong balance fails a check', () {
    final s = importer.read(_csv(_account.replaceFirst('2601.00', '2601.01')));
    expect(s.failedChecks, hasLength(2));
    expect(s.failedChecks.first, contains('(EOP)'));
  });

  test('account export: unknown line type is a warning with its masked type', () {
    final s = importer.read(_csv(_account.replaceFirst('Achat /ACME CORP', 'Nouveau /ACME CORP')));
    expect(s.warnings, ['unknown code (no code) Xxxxxxx / (1 line): counted as expense / refund']);
  });

  test('account export: unknown layouts are refused', () {
    void refused(String text, String message) => expect(
      () => importer.read(_csv(text)),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains(message))),
    );
    refused(_account.replaceFirst('"","","","","",1088.66', '"","",1.00,"","",1088.66'), 'column 12 holds a value');
    refused(_account.replaceFirst('Caisse ACME,1234567,ET01', 'Caisse ACME,7654321,ET01'), '2 folios');
    refused(_account.replaceFirst('"",12.34,""', '"",12.34,1.00'), 'exactly one of withdrawal / deposit');
    refused(_account.replaceFirst('2026/10/04', '2026/09/01'), 'not in date order');
  });

  test('card export: merchant and location from fixed width, payment, refund; not checked', () {
    final s = importer.read(_csv(_card));
    expect(importer.format('desjardins-card')!.uncheckedFileTypes, {'csv'});
    expect(s.checkCount, 0);
    expect(s.warnings, isEmpty);
    expect(s.accounts.single.ref, 'card-4321');
    expect(s.accounts.single.name, 'Odyssee World Elite Mastercard');
    expect(
      [for (final l in s.lines) (l.amount, l.kind, l.merchantText, l.location)],
      [
        (-1200, TransactionKind.expense, 'ACME.COM', 'Internet'),
        (500, TransactionKind.refund, 'ACME, INC', 'MONTREAL QC'),
        (50000, TransactionKind.transfer, 'PAIEMENT CAISSE', null),
        (-4567, TransactionKind.expense, 'ACME CORP', 'MONTREAL QC'),
        (321, TransactionKind.income, 'CREDIT REMISE EN ARGENT BONIDOLLARS', null),
      ],
    );
  });

  test('anonymize: names, caisse, folio, card digits and messages replaced; reads the same', () {
    final account = importer.anonymize(_csv(_account), extra: ['ACME CORP']) as TextInput;
    expect(account.text, isNot(contains(RegExp('Caisse ACME|1234567|ACME CORP|merci|PERSONNE09'))));
    expect(account.text, contains('Virement envoyé à /PERSONNE01 /Loyer'));
    final a = importer.read(account), original = importer.read(_csv(_account));
    expect(
      [for (final l in a.lines) (l.date, l.amount, l.kind)],
      [for (final l in original.lines) (l.date, l.amount, l.kind)],
    );

    final card = importer.anonymize(_csv(_card)) as TextInput;
    expect(card.text, isNot(contains('4321')));
    expect(importer.read(card).lines.map((l) => l.location), importer.read(_csv(_card)).lines.map((l) => l.location));
  });
}
