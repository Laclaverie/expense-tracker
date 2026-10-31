/// A made-up household (no real data) and its bank statements: the synthetic
/// fixtures of the bank plug-ins and the demo database (`dart run demo:fixtures`,
/// `dart run demo:database`).
library;

export 'src/desjardins/card_statement.dart' show newCardLayoutFrom;
export 'src/desjardins/statements.dart';
export 'src/household.dart';
export 'src/life.dart';
export 'src/persona.dart' show lifeEnd, lifeStart;
