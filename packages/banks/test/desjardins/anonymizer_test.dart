import 'package:banks/desjardins.dart';
import 'package:pdf_words/pdf_words.dart';
import 'package:test/test.dart';

/// Builds a page from rows of `(y, [(x, text), ...])`.
DocumentWords doc(List<(double, List<(double, String)>)> rows) => DocumentWords([
  PageWords(612, 792, [
    for (final (y, words) in rows)
      for (final (x, text) in words) Word(text, x, x + text.length * 5, y),
  ]),
]);

final sample = doc([
  (98, [(259, 'RELEVÉ'), (306, 'DE'), (324, 'COMPTE')]),
  (100, [(107, 'DESJARDINS'), (391, 'Folio')]),
  (110, [(425, '12345')]),
  (122, [(197, 'SJ'), (215, '815-12345-6')]),
  (142, [(65, 'JEANNE'), (113, 'DUPONT')]),
  (152, [(65, '42'), (95, 'RUE'), (119, 'DES-LILAS'), (203, 'UNITE'), (239, '12')]),
  (163, [(65, 'MONTREAL'), (119, 'QC'), (143, 'H2X'), (167, '1Y1')]),
  (
    300,
    [
      (55, '9'),
      (65, 'SEP'),
      (84, 'VMW'),
      (108, 'Virement'),
      (144, 'Interac'),
      (171, 'à'),
      (178, '/'),
      (182, 'PAUL'),
      (205, 'MARTIN/'),
      (412, '20.00'),
    ],
  ),
  (
    312,
    [
      (55, '9'),
      (65, 'SEP'),
      (84, 'VMW'),
      (108, 'Virement'),
      (144, 'envoyé'),
      (171, 'à'),
      (178, '/'),
      (182, 'Ana'),
      (205, 'Lopez'),
      (240, '/Loyer'),
      (412, '900.00'),
    ],
  ),
  (
    318,
    [
      (55, '9'),
      (65, 'SEP'),
      (84, 'IVMW'),
      (108, 'Virement'),
      (144, 'reçu'),
      (162, 'de'),
      (173, '/'),
      (177, 'LEA'),
      (228, 'ROUSSEAU'),
      (272, '/Massage'),
      (479, '75.00'),
    ],
  ),
  (324, [(55, '9'), (65, 'SEP'), (84, 'DI'), (108, 'Paie'), (126, '/'), (130, 'ACMECORP'), (471, '1200.00')]),
  (
    336,
    [
      (55, '9'),
      (65, 'SEP'),
      (84, 'ACH'),
      (108, 'Achat'),
      (140, '/'),
      (150, 'AIRBNB'),
      (190, 'HMSXXK2NBM'),
      (412, '50.00'),
    ],
  ),
  (
    348,
    [
      (55, '9'),
      (65, 'SEP'),
      (84, 'ACH'),
      (108, 'Achat'),
      (140, '/'),
      (150, 'CAFE'),
      (190, 'MONTREAL'),
      (240, 'QC'),
      (412, '4.50'),
    ],
  ),
]);

String allText(DocumentWords d) => d.pages.expand((p) => p.words).map((w) => w.text).join(' ');

void main() {
  final out = anonymize(sample, extra: ['ACMECORP']);
  final text = allText(out);

  test('removes holder, address, numbers, counterparties, references, extra words', () {
    for (final secret in [
      'JEANNE',
      'DUPONT',
      'DES-LILAS',
      'H2X',
      '1Y1',
      '12345',
      '815-12345-6',
      'PAUL',
      'MARTIN',
      'Ana',
      'Lopez',
      'LEA',
      'ROUSSEAU',
      'ACMECORP',
      'HMSXXK2NBM',
    ]) {
      expect(text, isNot(contains(secret)), reason: secret);
    }
  });

  test('keeps merchants, cities outside the address block, amounts and the rent marker', () {
    for (final kept in ['CAFE MONTREAL QC', 'Virement', '20.00', '900.00', '/Loyer', 'AIRBNB']) {
      expect(text, contains(kept), reason: kept);
    }
  });

  test('replaces with stable placeholders', () {
    expect(text, contains('TITULAIRE TEST'));
    expect(text, contains('PERSONNE01/'));
    expect(text, contains('PERSONNE02 /Loyer'));
    expect(text, contains('reçu de / PERSONNE03 /Massage'));
    expect(text, contains('Paie / MASQUE'));
    expect(text, contains('AIRBNB XXXXXX9XXX')); // booking reference, same shape
    expect(text, contains('99 XXX XXX-XXXXX XXXXX 99')); // street line masked, same shape
  });

  test('keeps word positions', () {
    final amount = out.pages.single.words.firstWhere((w) => w.text == '900.00');
    expect((amount.x0, amount.y), (412, 312));
  });

  test('rejects documents that are not Desjardins statements', () {
    expect(
      () => anonymize(
        doc([
          (100, [(10, 'Hello')]),
        ]),
      ),
      throwsFormatException,
    );
  });
}
