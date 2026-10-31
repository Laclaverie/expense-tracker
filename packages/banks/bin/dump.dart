// Shows a statement file the way a parser sees it: the first step when writing
// a reader for a new bank or file type. OUTPUT CONTAINS PERSONAL DATA: read it
// locally, never commit or paste it anywhere.
//
// Usage: dart run banks:dump [--json out.json | --out dump.txt] [--page N] <statement file>
//   PDF:   rows by baseline, `y=123.4 | 54:28 64:FEV 84:VMW 108:Virement ...` (x:text)
//          --json writes the raw word dump instead (input for parse/anonymize)
//   text (CSV, OFX…): numbered lines as decoded (UTF-8 or Windows-1252)
import 'dart:convert';
import 'dart:io';

import 'package:banks/files.dart';
import 'package:banks/plugin.dart';

void main(List<String> args) {
  String? json, out;
  int? onlyPage;
  final files = <String>[];
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--json':
        json = args[++i];
      case '--out':
        out = args[++i];
      case '--page':
        onlyPage = int.parse(args[++i]);
      default:
        files.add(args[i]);
    }
  }
  if (files.length != 1) {
    stderr.writeln('Usage: dart run banks:dump [--json out.json | --out dump.txt] [--page N] <statement file>');
    exitCode = 64;
    return;
  }
  final o = StringBuffer();
  final input = loadOrReport(files.single);
  if (input == null) return;
  switch (input) {
    case TextInput(:final lines, :final fileType):
      o.writeln('=== $fileType, ${lines.length} non-empty lines');
      for (final (i, l) in lines.indexed) {
        o.writeln('${'${i + 1}'.padLeft(4)} | $l');
      }
    case PdfInput(:final words):
      if (json != null) {
        File(json).writeAsStringSync(jsonEncode(words.toJson()));
        stdout.writeln('${words.pages.length} pages -> $json');
        return;
      }
      for (final (p, page) in words.pages.indexed) {
        if (onlyPage != null && onlyPage != p + 1) continue;
        o.writeln('=== page ${p + 1} (${page.width.round()} x ${page.height.round()} pt)');
        for (final row in groupRows(page.words)) {
          o.writeln(
            'y=${row.words.first.y.toStringAsFixed(1).padLeft(6)} | '
            '${row.words.map((w) => '${w.x0.round()}:${w.text}').join(' ')}',
          );
        }
      }
  }
  if (out == null) {
    stdout.write(o);
  } else {
    File(out).writeAsStringSync(o.toString());
  }
}
