import 'package:banks/plugin.dart';

import 'pdf/detect.dart';

/// Returns a copy of a Desjardins statement word dump with personal data
/// replaced, keeping layout, dates, amounts and merchants so parsers behave
/// exactly as on the original.
///
/// Replaced:
/// - holder name (everywhere) and postal address block;
/// - account transit, folio, TFSA contract and other long numbers;
/// - card number last 4 digits (consistently: same card, same fake number);
/// - Interac counterparties (`Virement Interac à / NAME/` -> `PERSONNE01/`);
/// - booking/ticket references (alphanumeric codes of 8+ characters);
/// - every word listed in [extra] (e.g. employer, insurance policy number).
///
/// After replacing, the result is scanned for every secret found; any match
/// throws [AnonymizationLeak].
DocumentWords anonymize(DocumentWords doc, {Iterable<String> extra = const []}) {
  final format = detectFormat(doc);
  if (format == null) throw const FormatException('Not a recognized Desjardins statement');
  final extraUpper = {for (final e in extra) e.trim().toUpperCase()}..remove('');
  final secrets = {...extraUpper};
  final replacements = <String, String>{};
  final pages = [for (final p in doc.pages) groupRows(p.words)];

  // Holder name: first all-caps row of 2+ words near the left margin below the header.
  final nameRow = pages.first.firstWhere(
    (r) => r.y > 130 && r.words.first.x0 < 100 && r.words.length >= 2 && r.texts.every(isUpperName),
    orElse: () => throw const FormatException('Holder name not found'),
  );
  final name = [
    for (final w in nameRow.words)
      if (w.x0 < 300) w.text,
  ];
  secrets.addAll(name);
  final fakeName = ['TITULAIRE', 'TEST', 'X', 'X', 'X'];
  for (final (i, n) in name.indexed) {
    replacements[n.toUpperCase()] = fakeName[i < fakeName.length ? i : fakeName.length - 1];
  }

  final interac = <String, String>{};
  final cards = <String, String>{};
  final out = <PageWords>[];
  for (final (p, rows) in pages.indexed) {
    final words = <Word>[];
    var addressRows = 0;
    var afterFolio = false;
    for (final row in rows) {
      final t = row.texts;
      final isNameRow = startsWithWords(t, name);
      if (isNameRow) addressRows = 3; // name, street line, city line
      // Rows with nothing in the left column (e.g. card payment box) don't count.
      final left = row.words.any((w) => w.x0 < 300);
      final addressLine = isNameRow || !left ? 0 : 3 - addressRows; // 1 = street, 2 = city
      if (addressRows > 0 && left) addressRows--;
      for (final (i, w) in row.words.indexed) {
        var text = w.text;
        if (addressLine > 0 && addressLine < 3 && w.x0 < 300) {
          // Street line: all but street-type words are secret. City line: only
          // the postal code (city and province also appear in merchant lines).
          final secret = addressLine == 1
              ? !streetWords.contains(text.toUpperCase().replaceAll(',', ''))
              : RegExp(r'\d').hasMatch(text);
          if (secret) secrets.add(text.toUpperCase().replaceAll(',', ''));
          text = mask(text);
        }
        if (afterFolio && RegExp(r'^\d{4,6}$').hasMatch(text)) {
          secrets.add(text);
          text = mask(text);
          afterFolio = false;
        }
        if (text == 'Folio') afterFolio = true;
        // Card digits follow `****` (original layout) or `XXXX` (2026-10 layout).
        if (i > 0 && const {'****', 'XXXX'}.contains(row.words[i - 1].text) && RegExp(r'^\d{4}$').hasMatch(text)) {
          secrets.add(text);
          text = cards.putIfAbsent(text, () => (cards.length + 1).toString().padLeft(4, '0'));
        }
        // Full dates (`2026/09/19`) and exchange rates (`1.46111111`) have 8+ digits but are not secret.
        final notSecret = RegExp(r'^(\d{4}/\d{2}/\d{2}|\d+\.\d+)$').hasMatch(text);
        if (!notSecret && (RegExp(r'^\d{3}-\d{5}-\d$').hasMatch(text) || isLongNumber(text) || isReference(text))) {
          secrets.add(text);
          text = mask(text);
        }
        text = replacements[text.toUpperCase()] ?? text;
        text = _maskInside(text, name);
        if (extraUpper.contains(text.toUpperCase())) text = 'MASQUE';
        words.add(w.withText(text));
      }
    }
    _replaceInterac(words, interac, secrets);
    out.add(PageWords(doc.pages[p].width, doc.pages[p].height, words));
  }

  final result = DocumentWords(out);
  verifyAnonymized(result, secrets);
  return result;
}

/// Masks a holder name part found inside a longer word (a city named after
/// it, in a merchant location), keeping the word's length.
String _maskInside(String text, List<String> name) {
  for (final n in name) {
    if (n.length < 5) continue;
    final at = text.toUpperCase().indexOf(n.toUpperCase());
    if (at >= 0 && text.length > n.length) {
      return text.replaceRange(at, at + n.length, mask(text.substring(at, at + n.length)));
    }
  }
  return text;
}

/// Account statement Interac lines: `Virement Interac à / NAME/`,
/// `Virement envoyé à / Name /Loyer`, `Virement reçu de / NAME /Rbsm` (older
/// statements, code IVMW). The name is between the first `/` and the
/// next word ending with `/` (included) or starting with `/` (excluded).
void _replaceInterac(List<Word> words, Map<String, String> people, Set<String> secrets) {
  final rows = groupRows(words);
  final byIdentity = {for (final (i, w) in words.indexed) w: i};
  for (final row in rows) {
    final t = row.texts;
    final interac = t.indexWhere((x) => x == 'Interac' || x == 'envoyé' || x == 'reçu');
    if (interac < 0 || !t.take(4).any((x) => x == 'VMW' || x == 'IVMW')) continue;
    final slash = t.indexOf('/', interac);
    if (slash < 0) continue;
    final nameWords = <Word>[];
    for (final w in row.words.skip(slash + 1)) {
      if (w.text.startsWith('/') || w.text == '/' || w.x0 > 330) break;
      nameWords.add(w);
      if (w.text.endsWith('/')) break;
    }
    if (nameWords.isEmpty) continue;
    final key = nameWords.map((w) => w.text.replaceAll('/', '')).join(' ').toUpperCase();
    final fake = people.putIfAbsent(key, () => 'PERSONNE${(people.length + 1).toString().padLeft(2, '0')}');
    for (final w in nameWords) {
      final clean = w.text.replaceAll('/', '');
      if (clean.length >= 3) secrets.add(clean.toUpperCase());
    }
    final trailing = nameWords.last.text.endsWith('/') ? '/' : '';
    for (final (i, w) in nameWords.indexed) {
      final index = byIdentity[w]!;
      words[index] = w.withText(i == 0 ? '$fake$trailing' : '');
    }
  }
  words.removeWhere((w) => w.text.isEmpty);
}
