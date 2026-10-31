import 'package:banks/compare.dart';
import 'package:banks/plugin.dart';
import 'package:banks/shape.dart';
import 'package:test/test.dart';

ImportedLine _line(int day, int amount, String description, {String? code, int? posted, TransactionKind? kind}) =>
    ImportedLine(
      accountRef: 'EOP',
      date: DateTime.utc(2026, 9, day),
      postedDate: posted == null ? null : DateTime.utc(2026, 9, posted),
      amount: amount,
      description: description,
      code: code,
      kind: kind ?? (amount < 0 ? TransactionKind.expense : TransactionKind.income),
      merchantText: description.split('/').last.trim(),
    );

ImportedStatement _statement(int from, int to, List<ImportedLine> lines) => ImportedStatement(
  institution: 'desjardins',
  format: 'desjardins-account',
  periodStart: DateTime.utc(2026, 9, from),
  periodEnd: DateTime.utc(2026, 9, to),
  accounts: const [ImportedAccount(ref: 'EOP', name: 'EOP', type: AccountType.checking, currency: 'CAD')],
  lines: lines,
  failedChecks: const [],
  checkCount: 1,
);

void main() {
  test('pairs lines by date, posting date and nearby dates; reports counts without data', () {
    final pdf = _statement(1, 30, [
      _line(2, -1234, 'Achat / ACME CORP', code: 'ACH'),
      _line(3, -500, 'Achat / ACME CORP', code: 'ACH', posted: 4),
      _line(10, -2000, 'Achat / PERSONNE01', code: 'ACH'),
      _line(20, 99999, 'Paie / ACME CORP', code: 'DI'),
      _line(25, -700, 'Frais', code: 'FIX', kind: TransactionKind.fee),
    ]);
    final csv = _statement(5, 30, [
      _line(10, -2000, 'Virement Interac à /PERSONNE01', kind: TransactionKind.transfer),
      _line(21, 99999, 'Paie /ACME CORP INC'),
      _line(26, -800, 'Frais', kind: TransactionKind.fee),
    ]);
    final report = compareSources([Source('pdf', pdf), Source('csv', csv)], Reveal());
    expect(report, [
      '== desjardins XXX: 2026-09-10..2026-09-26 (days covered by both sources)',
      '   lines: PDF 3, export 3; paired 2 (sameDate 1, postedDate 0, nearDate 1)',
      '   unpaired: PDF 1, export 1',
      '     2026-09: PDF only 1, export only 1',
      '   unpaired by line type:',
      '     1x PDF FIX',
      '     1x export Frais',
      '   totals over common days: DIFFERENT',
      '   line types of paired lines (PDF -> export):',
      '     1x ACH -> "Virement Xxxxxxx x /"',
      '     1x DI -> "Xxxx /"',
      '   paired lines: same kind 1 of 2, same category hint 2 of 2, same merchant 1 of 2',
      '   kind differences:',
      '     1x PDF ACH expense -> export "Virement Xxxxxxx x /" transfer',
      '   merchant differences, accents and case aside (masked, up to 8):',
      '     "XXXX XXXX" vs "XXXX XXXX XXX"',
    ]);
    expect(report.join('\n'), isNot(contains(RegExp('ACME|1234|999|PERSONNE'))));
  });

  test('a PDF saved twice counts once; an export card maps to the PDF card account', () {
    ImportedStatement card(String ref, List<ImportedLine> lines) => ImportedStatement(
      institution: 'desjardins',
      format: 'desjardins-card',
      periodStart: DateTime.utc(2026, 9, 1),
      periodEnd: DateTime.utc(2026, 9, 30),
      accounts: [ImportedAccount(ref: ref, name: 'Card', type: AccountType.creditCard, currency: 'CAD')],
      lines: lines,
      failedChecks: const [],
      checkCount: 1,
    );
    ImportedLine line(String ref, {String? card}) => ImportedLine(
      accountRef: ref,
      date: DateTime.utc(2026, 9, 5),
      amount: -1000,
      description: 'ACME',
      kind: TransactionKind.expense,
      merchantText: 'ACME',
      card: card,
    );
    final pdf = card('card-0001', [line('card-0001', card: '0002')]);
    final csv = card('card-0002', [line('card-0002')]);
    final report = compareSources([Source('pdf', pdf), Source('pdf', pdf), Source('csv', csv)], Reveal());
    expect(report.take(3), [
      '1 PDF(s) skipped: same statement as another PDF',
      'export card-9999 is a card used on the PDF account card-9999: compared as one',
      '== desjardins card-9999: 2026-09-05..2026-09-05 (days covered by both sources)',
    ]);
    expect(report, contains('   lines: PDF 1, export 1; paired 1 (sameDate 1, postedDate 0, nearDate 0)'));
  });

  test('needs both sources', () {
    expect(compareSources([], Reveal()).single, contains('need PDF statements'));
  });
}
