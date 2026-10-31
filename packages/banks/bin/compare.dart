// Compares the same accounts read from monthly PDF statements and from an
// export (CSV…), over the days both cover, and prints a report WITHOUT
// statement data, safe for a coding agent running in the cloud
// (docs/10-adding-a-bank.md §0b): lines paired by account, amount and date
// (same date, the PDF's posting date, or up to 3 days apart), unpaired lines
// per month and masked line type, kind / category hint / merchant text
// agreement, whether totals are equal. Anything the parsers print is hidden.
//
// Usage: dart run banks:compare [--reveal <reveal.txt>] <statements and exports, or folders> ...
import 'dart:io';

import 'package:banks/check.dart';
import 'package:banks/compare.dart';
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
    stderr.writeln('Usage: dart run banks:compare [--reveal <reveal.txt>] <statements and exports, or folders> ...');
    exitCode = 64;
    return;
  }
  final sources = <Source>[];
  final captured = Swallow();
  var unread = 0;
  for (final path in expandStatementPaths(files)) {
    try {
      final read = readQuietly(() => loadStatementInput(path), captured);
      if (read == null) {
        unread++;
      } else {
        sources.add(Source(read.fileType, read.statement));
      }
    } on Object {
      unread++;
    }
  }
  stdout.writeln(
    '${sources.where((s) => s.fileType == 'pdf').length} PDF(s), '
    '${sources.where((s) => s.fileType != 'pdf').length} export(s) read'
    '${unread == 0 ? '' : ', $unread file(s) not read (run banks:check on them)'}',
  );
  for (final l in [...compareSources(sources, Reveal.file(reveal)), ...captured.note]) {
    stdout.writeln(l);
  }
}
