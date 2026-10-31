// Shows a statement file without its content, for a coding agent running in
// the cloud (docs/10-adding-a-bank.md §0b): letters -> X / x, digits -> 9,
// layout and punctuation kept; only statement words and words of an approved
// reveal list stay readable.
//
// Usage:
//   dart run banks:shape --candidates <reveal.txt> [--min-files N] <statement file> ...
//       Writes the words that could stay readable (found in N+ files, default 2)
//       to reveal.txt, for the statement's OWNER to review: delete every
//       personal word. Prints only a count. Refuses a path inside a git repository.
//   dart run banks:shape [--reveal <reveal.txt>] [--page N] [--json out.json | --out shape.txt] <statement file> ...
//       PDF:  rows by baseline, `y=123.4 | 54-90:XXXXX 96-110:SOLDE ...` (x0-x1:text)
//             --json writes a masked word dump (one file only)
//       text: numbered lines, masked (OFX / QFX tags kept), after facts about its columns
//   dart run banks:shape --facts <statement file or folder> ...
//       only the facts about a CSV's columns (counts and formats, no value)
import 'dart:convert';
import 'dart:io';

import 'package:banks/files.dart';
import 'package:banks/plugin.dart';
import 'package:banks/shape.dart';

void main(List<String> args) {
  String? candidates, reveal, json, out;
  int? onlyPage, minFiles;
  var factsOnly = false;
  final files = <String>[];
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--candidates':
        candidates = args[++i];
      case '--min-files':
        minFiles = int.parse(args[++i]);
      case '--reveal':
        reveal = args[++i];
      case '--json':
        json = args[++i];
      case '--out':
        out = args[++i];
      case '--facts':
        factsOnly = true;
      case '--page':
        onlyPage = int.parse(args[++i]);
      default:
        files.add(args[i]);
    }
  }
  if (files.isEmpty || (json != null && files.length != 1)) {
    stderr.writeln(
      'Usage: dart run banks:shape --candidates <reveal.txt> [--min-files N] <statement file> ...\n'
      '       dart run banks:shape [--reveal <reveal.txt>] [--page N] [--json out.json | --out shape.txt] <statement file> ...',
    );
    exitCode = 64;
    return;
  }

  if (candidates != null) {
    if (insideGitRepository(candidates)) {
      stderr.writeln('Refused: $candidates is inside a git repository. Write it next to the statements.');
      exitCode = 1;
      return;
    }
    final inputs = [for (final f in files) ?loadOrReport(f)];
    final words = revealCandidates(inputs, minFiles: minFiles ?? (files.length >= 2 ? 2 : 1));
    File(candidates).writeAsStringSync(
      [
        '# Words banks:shape and banks:check may show to a coding agent, from ${files.length} statement file(s).',
        '# DELETE every line with personal data: names (yours, family, people you pay), street, city,',
        '# employer, account nicknames, shops you would rather keep private.',
        '# KEEP statement words: column headers, section titles, transaction codes, month names.',
        '# Words with digits are always masked. Number after # = files the word appears in.',
        for (final (w, n) in words) '$w  # $n',
        '',
      ].join('\n'),
    );
    stdout.writeln('${words.length} candidate words written. The statement owner reviews the file, then:');
    stdout.writeln('  dart run banks:shape --reveal <reveal.txt> <statement file>');
    return;
  }

  final o = StringBuffer();
  final r = Reveal.file(reveal);
  for (final (n, path) in expandStatementPaths(files).indexed) {
    final input = loadOrReport(path);
    if (input == null) continue;
    if (input case PdfInput(:final words) when json != null) {
      final masked = maskWords(words, r);
      File(json).writeAsStringSync(jsonEncode({...masked.toJson(), 'masked': true}));
      stdout.writeln('${masked.pages.length} pages -> $json');
      return;
    }
    if (factsOnly) {
      o.writeln('=== [${n + 1}] ${input.fileType}');
      if (input is TextInput) csvFacts(input).forEach(o.writeln);
      continue;
    }
    o.write(shapeText(input, r, heading: '[${n + 1}] ', onlyPage: onlyPage));
  }
  if (out == null) {
    stdout.write(o);
  } else {
    File(out).writeAsStringSync(o.toString());
  }
}
