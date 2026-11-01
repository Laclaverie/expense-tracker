// Writes the bank plug-ins' test fixtures from the made-up household:
// `packages/banks/test/fixtures/<bank>/<format>-YYYY-MM.synthetic.json`, word
// dumps shaped like the bank's PDFs. No real statement goes in the repository.
//
// Usage (from packages/demo): dart run demo:fixtures
//   Rewrites the months below; run it after changing the persona or a writer,
//   then the bank tests (some read planted lines: a refund, a USD purchase…).
import 'dart:io';

import 'package:demo/demo.dart';

/// Months kept as fixtures: the account statements of April to September
/// 2026 except June (a missing statement), the card statements of 2026 (both
/// layouts, December lines on a January statement, two cards, a USD trip).
final _accountMonths = ['2026-04', '2026-05', '2026-07', '2026-08', '2026-09'];
final _cardMonths = [for (var m = 1; m <= 10; m++) '2026-${m.toString().padLeft(2, '0')}'];

void main() {
  final out = Directory('../banks/test/fixtures/desjardins');
  if (!out.existsSync()) {
    stderr.writeln('Run from packages/demo.');
    exitCode = 66;
    return;
  }
  final wanted = {
    for (final m in _accountMonths) 'desjardins-account-$m',
    for (final m in _cardMonths) 'desjardins-card-$m',
  };
  for (final s in desjardinsStatements(liveHousehold())) {
    if (!wanted.remove(s.name)) continue;
    final file = File('${out.path}/${s.name}.synthetic.json');
    file.writeAsStringSync(fixtureJson(s));
    stdout.writeln(file.path);
  }
  if (wanted.isNotEmpty) throw StateError('Not in the household\'s life: $wanted');
}
