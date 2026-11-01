import 'couple.dart';
import 'freelancer.dart';
import 'persona.dart';

/// Every persona, by the id `demo:showcase --persona` takes.
final Map<String, Persona> personas = {
  for (final p in [couple, freelancer]) p.id: p,
};
