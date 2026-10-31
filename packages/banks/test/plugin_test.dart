import 'package:banks/plugin.dart';
import 'package:test/test.dart';

DocumentWords doc(List<String> words) => DocumentWords([
  PageWords(612, 792, [for (final (i, w) in words.indexed) Word(w, i * 50.0, i * 50.0 + 40, 100)]),
]);

void main() {
  test('mask keeps the shape, not the content', () {
    expect(mask('FR76-3000 Ab'), 'XX99-9999 XX');
    expect(mask('Élise'), 'XXXXX');
  });

  test('long numbers and references', () {
    expect([isLongNumber('815-12345-6'), isLongNumber('12345'), isLongNumber('0612 34 56 78')], [true, false, true]);
    expect([isReference('HMSXXK2NBM'), isReference('MONTREAL'), isReference('12345678')], [true, false, false]);
  });

  test('verifyAnonymized: short secrets match whole words, long ones anywhere, case-insensitive', () {
    verifyAnonymized(doc(['CAFE', 'MONTREAL', 'QCX']), {'QC', 'DUPONT'});
    expect(() => verifyAnonymized(doc(['qc']), {'QC'}), throwsA(isA<AnonymizationLeak>()));
    expect(() => verifyAnonymized(doc(['MME-DUPONT/']), {'Dupont'}), throwsA(isA<AnonymizationLeak>()));
  });

  test('a leak message never repeats the secret', () {
    expect(AnonymizationLeak(2).toString(), isNot(contains('DUPONT')));
  });
}
