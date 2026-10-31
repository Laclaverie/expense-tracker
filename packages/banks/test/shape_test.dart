import 'dart:io';

import 'package:banks/check.dart';
import 'package:banks/plugin.dart';
import 'package:banks/shape.dart';
import 'package:test/test.dart';

/// Reads `ACME;<amount>` lines; prints debug output, fails or throws on demand.
class FakeBank extends BankImporter {
  const FakeBank();

  @override
  String get institution => 'fake';
  @override
  String get displayName => 'Fake';
  @override
  String get country => 'CA';
  @override
  List<StatementFormat> get formats => const [
    StatementFormat(id: 'fake-account', labelFr: 'Compte', labelEn: 'Account', accountType: AccountType.checking),
  ];

  @override
  String? detect(StatementInput input) => input is TextInput && input.text.startsWith('ACME') ? 'fake-account' : null;

  @override
  ImportedStatement read(StatementInput input) {
    final lines = (input as TextInput).lines;
    print('debug ${lines.first}');
    stdout.writeln('debug ${lines.first}');
    if (lines.first.contains('THROW')) throw const FormatException('Bad line PERSONNE01 at 1 234,56');
    final amount = int.parse(lines.first.split(';').last);
    return ImportedStatement(
      institution: 'fake',
      format: 'fake-account',
      periodStart: DateTime.utc(2026, 9),
      periodEnd: DateTime.utc(2026, 9, 30),
      accounts: const [ImportedAccount(ref: 'A', name: 'PERSONNE01', type: AccountType.checking, currency: 'CAD')],
      lines: [
        ImportedLine(
          accountRef: 'A',
          date: DateTime.utc(2026, 9, 3),
          amount: amount,
          description: 'ACME PERSONNE01',
          kind: TransactionKind.expense,
          merchantText: 'ACME',
        ),
      ],
      failedChecks: [if (amount > 0) 'balance: expected 1 234,56 for PERSONNE01'],
      checkCount: 1,
    );
  }

  @override
  StatementInput anonymize(StatementInput input, {Iterable<String> extra = const []}) => input;
}

void main() {
  final reveal = Reveal(['acme']);

  test('maskText keeps layout, case and approved words only', () {
    expect(maskText('Solde PERSONNE01 Tremblay 1 234,56', reveal), 'Solde XXXXXXXX99 Xxxxxxxx 9 999,99');
    expect(maskText('ACME CORP; 2026-09-03', reveal), 'ACME XXXX; 9999-99-99');
    expect(maskText('Élise ÉPICERIE', Reveal()), 'Xxxxx XXXXXXXX');
  });

  test('words with digits are never revealed, even when approved', () {
    expect(maskText('AB12', Reveal(['AB12'])), 'XX99');
  });

  test('OFX: tags and header lines kept, values masked', () {
    expect(maskLine('OFXHEADER:100', 'ofx', reveal), 'OFXHEADER:100');
    expect(maskLine('<NAME>PERSONNE01</NAME>', 'ofx', reveal), '<NAME>XXXXXXXX99</NAME>');
    expect(maskLine('<TRNTYPE>DEBIT<TRNAMT>-12.34', 'qfx', reveal), '<TRNTYPE>DEBIT<TRNAMT>-99.99');
    expect(maskLine('<NAME>x</NAME>', 'csv', reveal), '<XXXX>x</XXXX>');
  });

  test('maskWords keeps coordinates', () {
    final masked = maskWords(
      DocumentWords([
        const PageWords(612, 792, [Word('DUPONT', 10, 40, 100), Word('SOLDE', 50, 80, 100)]),
      ]),
      reveal,
    );
    final w = masked.pages.single.words;
    expect([w[0].text, w[0].x0, w[0].x1, w[0].y, w[1].text], ['XXXXXX', 10, 40, 100, 'SOLDE']);
  });

  test('preview: first page rows masked, words joined; text lines masked', () {
    final pdf = PdfInput(
      'x.pdf',
      DocumentWords([
        const PageWords(612, 792, [
          Word('ACME', 10, 40, 100),
          Word('DUPONT', 50, 80, 100),
          Word('12,34', 90, 120, 120),
        ]),
        const PageWords(612, 792, [Word('PAGE2', 10, 40, 100)]),
      ]),
    );
    expect(shapePreview(pdf, reveal), ['ACME XXXXXX', '99,99']);
    expect(shapePreview(TextInput('x.csv', 'ACME;Dupont;12\nB;C;3', fileType: 'csv'), reveal, maxRows: 1), [
      'ACME;Xxxxxx;99',
    ]);
  });

  test('shapeText: heading, positions, one page', () {
    final pdf = PdfInput(
      'x.pdf',
      DocumentWords([
        const PageWords(612, 792, [Word('DUPONT', 10, 40, 100)]),
        const PageWords(612, 792, [Word('SOLDE', 10, 40, 100)]),
      ]),
    );
    expect(shapeText(pdf, reveal, heading: '[1] ', onlyPage: 2).split('\n'), [
      '=== [1] pdf, 2 pages',
      '--- page 2 (612 x 792 pt)',
      'y= 100.0 | 10-40:SOLDE',
      '',
    ]);
  });

  test('reveal candidates: words in enough files, no vocabulary, no digits', () {
    final inputs = [
      const TextInput('a.csv', 'Solde;ACME;DUPONT;Q3', fileType: 'csv'),
      const TextInput('b.csv', 'Solde;ACME;TREMBLAY', fileType: 'csv'),
    ];
    expect(revealCandidates(inputs, minFiles: 2), [('ACME', 2)]);
    expect(revealCandidates(inputs, minFiles: 1).map((c) => c.$1), ['ACME', 'DUPONT', 'TREMBLAY']);
  });

  test('reveal file: one word per line, # comments', () {
    final f = File('${Directory.systemTemp.createTempSync().path}/reveal.txt')..writeAsStringSync('acme  # 3\n# x\n\n');
    expect(Reveal.file(f.path).keeps('ACME'), isTrue);
  });

  test('candidate lists are refused inside a git repository', () {
    expect(insideGitRepository('reveal.txt'), isTrue); // tests run inside the clone
    expect(insideGitRepository('${Directory.systemTemp.createTempSync().path}/reveal.txt'), isFalse);
  });

  group('CSV helpers', () {
    test('splitCsvLine: quotes, doubled quotes, separators inside quotes', () {
      expect(splitCsvLine('a,"b,c","","d ""x"""'), ['a', 'b,c', '', 'd "x"']);
      expect(splitCsvLine('a;b', separator: ';'), ['a', 'b']);
      expect(guessCsvSeparator(['a;b;c', 'd;e;f']), ';');
    });

    test('parseCsvCents: signs, thousands, decimal comma; null otherwise', () {
      expect(parseCsvCents('1234.56'), 123456);
      expect(parseCsvCents('1 234,56'), 123456);
      expect(parseCsvCents('1,234.56'), 123456);
      expect(parseCsvCents('-12.30'), -1230);
      expect(parseCsvCents('12.30-'), -1230);
      expect(parseCsvCents('(12.30)'), -1230);
      expect(parseCsvCents(r'$12.30'), 1230);
      expect(parseCsvCents('12345'), isNull);
      expect(parseCsvCents(''), isNull);
    });

    test('parseCsvDate: year first or last; invalid dates refused', () {
      expect(parseCsvDate('2026/10/31'), DateTime.utc(2026, 10, 31));
      expect(parseCsvDate('31/10/2026'), DateTime.utc(2026, 10, 31));
      expect(parseCsvDate('10/31/2026', dayFirst: false), DateTime.utc(2026, 10, 31));
      expect(parseCsvDate('2026/02/30'), isNull);
      expect(parseCsvDate('ACME'), isNull);
    });
  });

  test('csvFacts: columns, blocks, order and running balance, without values', () {
    const csv =
        'Caisse ACME,1234567,EOP,2026/10/03,00012,Paiement ACME CORP,"",12.34,"",987.66\n'
        'Caisse ACME,1234567,EOP,2026/10/02,00011,Paie /ACME CORP,"",,500.00,1000.00\n'
        'Caisse ACME,1234567,EOP,2026/10/01,00010,Frais,"",4.95,"",500.00\n'
        'Caisse ACME,1234567,ET01,2026/10/02,00003,Interet,"","",0.12,100.12\n'
        'Caisse ACME,1234567,ET01,2026/10/01,00002,Virement,"","",100.00,100.00\n';
    final facts = csvFacts(const TextInput('x.csv', csv, fileType: 'csv'));
    expect(facts, contains('# col 1: text, filled on every line, same value on every filled line'));
    expect(facts, contains('# col 4: date YYYY/MM/DD, filled on every line, 3 distinct values'));
    expect(facts, contains('# col 7: empty on every line'));
    expect(facts, contains('#   unique; between consecutive lines: 0 increase, 4 decrease'));
    expect(facts, contains('# lines grouped by col 3: 2 blocks of consecutive lines, one per value'));
    expect(facts, contains('# line order (col 4): newest first (per block)'));
    expect(
      facts.last,
      "# running balance: col 10 = previous line's col 10 - col 8 + col 9 (newest line first, balance after the line): "
      '3 of 3 consecutive pairs hold',
    );
    expect(facts.join('\n'), isNot(contains(RegExp('ACME|1234567|EOP|2026|987'))));
    expect(csvFacts(const TextInput('x.ofx', '<OFX>', fileType: 'ofx')), isEmpty);
  });

  group('checkStatement', () {
    Report check(String text) =>
        checkStatement(() => TextInput('x.csv', text, fileType: 'csv'), reveal, registry: const [FakeBank()]);

    test('valid statement: counts, no data, plug-in output swallowed', () {
      final r = check('ACME;-1234');
      expect(r.ok, isTrue);
      expect(r.lines.first, 'fake-account 2026-09-01..2026-09-30 VALID (1 checks)');
      expect(r.lines, contains('kinds: expense=1'));
      expect(r.lines.last, 'the plug-in printed 2 time(s): hidden (remove debug prints)');
      expect(r.lines.join('\n'), isNot(contains('PERSONNE01')));
      expect(r.lines.join('\n'), isNot(contains('1234')));
    });

    test('failed checks and errors are masked', () {
      final failed = check('ACME;5');
      expect(failed.ok, isFalse);
      expect(failed.lines, contains('FAILED balance: expected 9 999,99 for XXXXXXXX99'));
      final error = check('ACME;THROW');
      expect(error.ok, isFalse);
      expect(error.lines.first, 'ERROR FormatException: Xxx line XXXXXXXX99 xx 9 999,99');
      expect(error.lines.any((l) => l.startsWith('at package:banks/') || l.contains('shape_test')), isTrue);
    });

    test('unrecognized file', () {
      expect(check('OTHER').lines.first, 'not recognized by any registered bank');
    });
  });
}
