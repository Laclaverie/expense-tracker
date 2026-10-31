import 'package:banks/banks.dart';
import 'package:banks/plugin.dart' show decodeStatementText;
import 'package:pdf_words/pdf_words.dart';
import 'package:test/test.dart';

void main() {
  test('registry: unique institutions and format ids, formats prefixed by their institution', () {
    expect({for (final b in banks) b.institution}, hasLength(banks.length));
    final ids = [for (final b in banks) ...b.formats.map((f) => f.id)];
    expect(ids.toSet(), hasLength(ids.length));
    for (final b in banks) {
      expect(b.institution, matches(RegExp(r'^[a-z0-9_]+$')));
      expect(b.institution, isNot('cash'), reason: 'reserved for cash wallets');
      expect(bankFor(b.institution), same(b));
      for (final f in b.formats) {
        expect(f.id, startsWith('${b.institution}-'));
      }
    }
  });

  test('an unknown document is refused with the supported banks listed', () {
    final pdf = PdfInput(
      'hello.pdf',
      DocumentWords([
        PageWords(612, 792, [Word('Hello', 10, 40, 100)]),
      ]),
    );
    expect(detectStatement(pdf), isNull);
    expect(() => readStatement(pdf), throwsA(isA<FormatException>()));
    const csv = TextInput('export.csv', 'Date;Amount\n2026-09-01;-1,00', fileType: 'csv');
    expect(detectStatement(csv), isNull, reason: 'no plug-in reads this CSV');
  });

  test('text exports are decoded from UTF-8, or Windows-1252 when not valid UTF-8', () {
    expect(decodeStatementText([0xEF, 0xBB, 0xBF, 0x63, 0x61, 0x66, 0xC3, 0xA9]), 'café');
    expect(decodeStatementText([0x63, 0x61, 0x66, 0xE9]), 'café');
    const t = TextInput('a.csv', 'a;b\r\n\r\n1;2\r', fileType: 'csv');
    expect(t.lines, ['a;b', '1;2']);
  });

  test('every format lists the file types it is read from', () {
    for (final b in banks) {
      for (final f in b.formats) {
        expect(f.fileTypes, isNotEmpty);
        expect(statementFileTypes, containsAll(f.fileTypes), reason: f.id);
      }
    }
  });

  test('statementFormat finds any registered format', () {
    expect(statementFormat('desjardins-card')?.labelEn, 'Mastercard');
    expect(statementFormat('nope'), isNull);
  });
}
