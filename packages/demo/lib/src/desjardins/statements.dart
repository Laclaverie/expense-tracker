import 'package:pdf_words/pdf_words.dart';

import '../life.dart';
import '../persona.dart';
import 'account_statement.dart';
import 'card_statement.dart';

/// A statement written from the household's life, named like a fixture
/// (`desjardins-card-2026-10`).
class SyntheticStatement {
  const SyntheticStatement(this.name, this.closing, this.words);

  final String name;
  final DateTime closing;
  final DocumentWords words;
}

/// Every Desjardins statement of [life], oldest first: one account statement
/// per calendar month, one card statement per closing date.
List<SyntheticStatement> desjardinsStatements(Life life) {
  String ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
  final out = <SyntheticStatement>[
    for (
      var m = DateTime.utc(lifeStart.year, lifeStart.month + 1);
      DateTime.utc(m.year, m.month + 1, 0).isBefore(lifeEnd);
      m = DateTime.utc(m.year, m.month + 1)
    )
      SyntheticStatement(
        'desjardins-account-${ym(m)}',
        DateTime.utc(m.year, m.month + 1, 0),
        writeAccountStatement(life, m),
      ),
    for (final c in life.cardStatementDates)
      SyntheticStatement('desjardins-card-${ym(c)}', c, writeCardStatement(life, c)),
  ]..sort((a, b) => a.closing.compareTo(b.closing));
  return out;
}
