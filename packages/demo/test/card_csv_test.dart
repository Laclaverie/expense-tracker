import 'package:banks/banks.dart';
import 'package:banks/desjardins.dart';
import 'package:demo/demo.dart';
import 'package:test/test.dart';

/// The held-back card period of the showcase, as AccèsD card exports: one
/// file per card, read back by the real CSV reader.
void main() {
  for (final persona in personas.values) {
    final life = liveHousehold(persona: persona);
    final closing = life.cardStatementDates.last;
    final previous = life.cardStatementDates[life.cardStatementDates.length - 2];
    final files = writeCardCsvs(life, closing);

    test('${persona.id}: one export per card used', () {
      final used = {
        for (final e in life.cardEntries)
          if (e.posted.isAfter(previous) && !e.posted.isAfter(closing) && !e.operation) e.card,
      };
      expect(files.keys.toSet(), {for (final c in used) 'releve-carte-$c.csv'});
    });

    test('${persona.id}: the exports read back as the period\'s card lines', () {
      final read = <(DateTime, int, String, String)>{};
      for (final MapEntry(key: name, value: text) in files.entries) {
        final input = TextInput(name, text, fileType: 'csv');
        expect(detectCsv(input), DesjardinsCsv.card, reason: name);
        final statement = readStatement(input);
        expect(statement.warnings, isEmpty, reason: name);
        expect(statement.accounts.single.ref, 'card-${name.substring(13, 17)}');
        read.addAll(statement.lines.map((l) => (l.date, l.amount, l.description, l.location ?? '')));
      }
      final written = life.cardEntries.where((e) => e.posted.isAfter(previous) && !e.posted.isAfter(closing));
      expect(read, written.map((e) => (e.date, e.amount, e.merchant, e.operation ? '' : e.location)).toSet());
    });
  }
}
