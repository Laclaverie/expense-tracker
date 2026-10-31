// Reads statements with whichever registered bank recognizes them and prints
// a summary per file (no personal data). Exit code 1 if any file is not
// recognized or fails a self-check.
//
// Usage: dart run banks:parse [-v] <statement file (pdf, csv, ofx…) | dump.json> ...
//   -v  also print every line and failed check (PERSONAL DATA: local only)
import 'dart:io';

import 'package:banks/plugin.dart';
import 'package:banks/banks.dart';
import 'package:banks/files.dart';

void main(List<String> args) {
  final verbose = args.contains('-v');
  final files = args.where((a) => a != '-v').toList();
  if (files.isEmpty) {
    stderr.writeln('Usage: dart run banks:parse [-v] <statement file | dump.json> ...');
    exitCode = 64;
    return;
  }
  var bad = 0;
  for (final path in files) {
    final name = path.split(RegExp(r'[\/]')).last;
    try {
      final s = readStatement(loadStatementInput(path));
      stdout.writeln('$name: ${summarize(s)}');
      if (!s.isValid) bad++;
      if (verbose) {
        for (final a in s.accounts) {
          stdout.writeln('  [${a.ref}] ${a.name} (${a.type.name}, ${a.currency}) closing=${a.closingBalance}');
        }
        for (final l in s.lines) {
          stdout.writeln(
            '  ${l.date.toIso8601String().substring(0, 10)} ${l.accountRef} ${l.kind.name.padRight(16)} '
            '${(l.amount / 100).toStringAsFixed(2).padLeft(10)}  ${l.description}'
            '${l.categoryHint == null ? '' : '  -> ${l.categoryHint}'}${l.isPerson ? '  (person)' : ''}',
          );
        }
        for (final c in s.failedChecks) {
          stdout.writeln('  FAILED $c');
        }
      }
    } on FormatException catch (e) {
      bad++;
      stdout.writeln('$name: ERROR ${e.message}');
    } on Exception catch (e) {
      bad++;
      stdout.writeln('$name: ERROR $e');
    }
  }
  exitCode = bad == 0 ? 0 : 1;
}
