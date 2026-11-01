/// Made-up personas (no real data) and their bank statements: the synthetic
/// fixtures of the bank plug-ins and the demo databases (`dart run demo:fixtures`,
/// `dart run demo:database`).
library;

export 'src/couple.dart';
export 'src/desjardins/card_statement.dart' show newCardLayoutFrom;
export 'src/desjardins/statements.dart';
export 'src/household.dart';
export 'src/life.dart';
export 'src/freelancer.dart';
export 'src/persona.dart' show Clients, Income, Persona, Salary, ShowState, TaxInstallment, lifeEnd, lifeStart;
export 'src/personas.dart';
