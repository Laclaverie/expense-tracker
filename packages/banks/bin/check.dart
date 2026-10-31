// Reads statements with the registered plug-ins and prints a report WITHOUT
// statement data, safe for a coding agent running in the cloud
// (docs/10-adding-a-bank.md §0b): format, period, line counts per kind,
// self-check results, warnings and errors (masked, see banks:shape), the
// parser's code location on errors. Anything the parser prints is swallowed.
// Exit code 1 if any file is not recognized, fails a check or has warnings.
//
// Usage: dart run banks:check [--reveal <reveal.txt>] <statement file> ...
import 'dart:io';

import 'package:banks/check.dart';
import 'package:banks/files.dart';
import 'package:banks/shape.dart';

void main(List<String> args) {
  String? reveal;
  final files = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--reveal') {
      reveal = args[++i];
    } else {
      files.add(args[i]);
    }
  }
  if (files.isEmpty) {
    stderr.writeln('Usage: dart run banks:check [--reveal <reveal.txt>] <statement file> ...');
    exitCode = 64;
    return;
  }
  final r = Reveal.file(reveal);
  final paths = expandStatementPaths(files);
  if (paths.isEmpty) {
    stderr.writeln('No statement file (pdf, csv, ofx…) found in: ${files.join(', ')}');
    exitCode = 1;
    return;
  }
  var bad = 0;
  for (final (n, path) in paths.indexed) {
    final type = path.contains('.') ? path.split('.').last.toLowerCase() : '?';
    final report = checkStatement(() => loadStatementInput(path), r);
    if (!report.ok) bad++;
    stdout.writeln('[${n + 1}] $type: ${report.lines.first}');
    for (final l in report.lines.skip(1)) {
      stdout.writeln('    $l');
    }
  }
  stdout.writeln('${paths.length - bad} of ${paths.length} file(s) OK');
  exitCode = bad == 0 ? 0 : 1;
}
