import 'package:banks/plugin.dart';

import 'reader.dart';

/// A copy of a Desjardins CSV export with personal data replaced, keeping
/// dates, amounts, balances and merchants so the reader behaves exactly as on
/// the original:
/// - caisse name → `CAISSE`, folio → `0000001` (also inside descriptions);
/// - card number last 4 digits → `0000`;
/// - Interac counterparties (`Virement Interac à /NAME/`, `Virement envoyé à`)
///   → `PERSONNE01/`…;
/// - Interac messages (column 16) emptied;
/// - long numbers, booking references and every word of [extra] masked.
///
/// The result is scanned for every secret found; a match throws
/// [AnonymizationLeak]. The copy must read to the same lines as the original.
TextInput anonymizeCsv(TextInput input, {Iterable<String> extra = const []}) {
  final kind = detectCsv(input) ?? (throw const FormatException('Not a Desjardins CSV export'));
  final original = readCsv(input);
  final extraUpper = {for (final e in extra) e.trim().toUpperCase()}..remove('');
  final secrets = {...extraUpper};
  final people = <String, String>{};

  String clean(String text) {
    var t = text;
    for (final s in secrets) {
      t = t.replaceAll(RegExp(RegExp.escape(s), caseSensitive: false), 'X' * s.length);
    }
    return t.split(' ').map((w) => isLongNumber(w) || isReference(w) ? mask(w) : w).join(' ');
  }

  final out = <String>[];
  for (final line in input.lines) {
    final r = desjardinsRow(line, kind == DesjardinsCsv.account ? 16 : 13);
    switch (kind) {
      case DesjardinsCsv.account:
        secrets
          ..add(r[0].trim().toUpperCase())
          ..add(r[1].trim());
        final folio = r[1].trim();
        r[0] = 'CAISSE';
        r[1] = '0000001';
        var d = r[5].replaceAll(folio, '0000001');
        final interac = RegExp(r'^((?:Annulation - )?Virement (?:Interac|envoyé) (?:à|de) /)([^/]+)(/?.*)$')
            .firstMatch(d);
        if (interac != null) {
          final name = interac[2]!.trim();
          secrets.add(name.toUpperCase());
          final fake = people.putIfAbsent(name, () => 'PERSONNE${(people.length + 1).toString().padLeft(2, '0')}');
          final pad = interac[2]!.endsWith(' ') ? ' ' : '';
          d = '${interac[1]}$fake$pad${interac[3]}';
        }
        r[5] = clean(d);
        r[15] = '';
      case DesjardinsCsv.card:
        final m = RegExp(r'(\d{4})\s*$').firstMatch(r[0]);
        if (m != null) {
          secrets.add(m[1]!);
          r[0] = r[0].replaceRange(m.start, m.start + 4, '0000');
        }
        // Keep the fixed width: the merchant / city split depends on it.
        final d = clean(r[5]);
        r[5] = d.length == r[5].length ? d : d.padRight(r[5].length).substring(0, r[5].length);
    }
    out.add(
      [for (final f in r) f.isEmpty ? '""' : (f.contains(',') || f.contains('"') ? '"${f.replaceAll('"', '""')}"' : f)]
          .join(','),
    );
  }

  final text = '${out.join('\r\n')}\r\n';
  secrets.removeWhere((s) => s.isEmpty || s == '0000' || s == '0000001');
  verifyTextAnonymized(text, secrets);
  final copy = TextInput(input.fileName, text, fileType: input.fileType);
  final again = readCsv(copy);
  var same = again.lines.length == original.lines.length && again.failedChecks.length == original.failedChecks.length;
  for (var i = 0; same && i < again.lines.length; i++) {
    same = again.lines[i].date == original.lines[i].date && again.lines[i].amount == original.lines[i].amount;
  }
  if (!same) throw const FormatException('Anonymized copy reads differently from the original');
  return copy;
}
