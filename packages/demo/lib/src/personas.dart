import 'couple.dart';
import 'persona.dart';

/// Every persona, by the id `demo:showcase --persona` takes.
final Map<String, Persona> personas = {
  for (final p in [couple]) p.id: p,
};
