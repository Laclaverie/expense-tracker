import 'package:storage/storage.dart';

import 'database.dart';
import 'desjardins/card_csv.dart';
import 'desjardins/statements.dart';
import 'household.dart';
import 'persona.dart';

/// Public on purpose: it only ever protects made-up personas.
const demoPassword = 'demo database password';

/// Fills [db] (empty) with what a demo starts from: every statement of
/// [persona] but the last card statement, everything imported reviewed
/// (except its merchants left to review), its targets. Returns the held-back
/// card period as AccèsD exports (file name → text), to drop on the Import
/// page during the demo.
Future<Map<String, String>> fillShowcaseDatabase(ExpenseDatabase db, Persona persona) async {
  final life = liveHousehold(persona: persona);
  final last = life.cardStatementDates.last;
  final statements = [
    for (final s in desjardinsStatements(life))
      if (!(s.closing == last && s.name.startsWith('desjardins-card'))) s,
  ];
  await importAndReview(db, life, statements, lifeEnd, reviewEverything: true);
  return writeCardCsvs(life, last);
}
