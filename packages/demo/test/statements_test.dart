import 'package:banks/banks.dart';
import 'package:banks/desjardins.dart';
import 'package:banks/plugin.dart';
import 'package:demo/demo.dart';
import 'package:test/test.dart';

void main() {
  final life = liveHousehold();
  final statements = desjardinsStatements(life);
  const importer = DesjardinsImporter();

  test('two years: an account statement per month, a card statement per closing', () {
    expect(statements.where((s) => s.name.startsWith('desjardins-account')), hasLength(23));
    expect(statements.where((s) => s.name.startsWith('desjardins-card')), hasLength(24));
  });

  test('the same seed lives the same life', () {
    final again = liveHousehold();
    expect(
      again.cardEntries.map((e) => '${e.posted} ${e.merchant} ${e.amount}'),
      life.cardEntries.map((e) => '${e.posted} ${e.merchant} ${e.amount}'),
    );
  });

  group('the Desjardins plug-in reads every statement back', () {
    for (final persona in personas.values) {
      for (final s in desjardinsStatements(liveHousehold(persona: persona))) {
        test('${persona.id} ${s.name}', () {
          final input = PdfInput('${s.name}.pdf', s.words);
          final format = importer.detect(input);
          expect(s.name, startsWith('$format-'));
          final read = importer.read(input);
          expect(read.failedChecks, isEmpty);
          expect(read.checkCount, greaterThan(0));
          expect(read.warnings, isEmpty, reason: 'every line matches a rule');
          for (final l in read.lines) {
            expect(l.amount, isNot(0));
          }
        });
      }
    }
  });

  test('card lines come back as written, in both layouts', () {
    for (final s in statements.where((s) => s.name.startsWith('desjardins-card'))) {
      final read = importer.read(PdfInput('${s.name}.pdf', s.words));
      final i = life.cardStatementDates.indexOf(s.closing);
      final from = i == 0 ? DateTime.utc(1900) : life.cardStatementDates[i - 1];
      final written = life.cardEntries.where((e) => e.posted.isAfter(from) && !e.posted.isAfter(s.closing));
      expect(
        read.lines.map((l) => (l.date, l.amount, l.description, l.location ?? '')).toSet(),
        written.map((e) => (e.date, e.amount, e.merchant, e.operation ? '' : e.location)).toSet(),
        reason: s.name,
      );
      final foreign = written.where((e) => e.foreign != null);
      expect(read.lines.where((l) => l.foreignCurrency == 'USD'), hasLength(foreign.length), reason: s.name);
    }
  });

  test('account balances end where the household left them', () {
    final last = statements.lastWhere((s) => s.name.startsWith('desjardins-account'));
    final read = importer.read(PdfInput('${last.name}.pdf', last.words));
    final balance = {...life.openings};
    for (final e in life.accountEntries.where((e) => !e.date.isAfter(last.closing))) {
      balance[e.account] = balance[e.account]! + e.amount;
    }
    expect({for (final a in read.accounts) a.ref: a.closingBalance}, balance);
    expect(balance.values.every((b) => b > 0), isTrue);
  });

  test('checking never goes below zero and does not pile up', () {
    var checking = life.openings['EOP']!;
    var low = checking, high = checking;
    for (final e in life.accountEntries.where((e) => e.account == 'EOP')) {
      checking += e.amount;
      if (checking < low) low = checking;
      if (checking > high) high = checking;
    }
    expect(low, greaterThan(0));
    expect(high, lessThan(1200000));
  });

  test('the old card layout until September 2026, the new one after', () {
    for (final s in statements.where((s) => s.name.startsWith('desjardins-card'))) {
      expect(cardLayout(s.words)!.name, s.closing.isBefore(newCardLayoutFrom) ? 'original' : '2026-10');
    }
  });
}
