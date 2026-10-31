// Turns real statements into test fixtures safe to commit.
//
// Usage: dart run banks:anonymize --out <dir> [--extra <file>] <statement file> ...
//   --extra  words to remove too, one per line (employer, policy number…).
//            Keep that file OUTSIDE the repository.
//
// A fixture is written only if (PDF: `<format>-YYYY-MM.anon.json` word dump;
// text export: `<format>-YYYY-MM.anon.<csv|ofx|…>`):
//   1. the original statement reads without failed checks,
//   2. the bank's anonymizer finds no remaining secret (AnonymizationLeak),
//   3. the anonymized copy reads to exactly the same dates, amounts, kinds and
//      check results as the original.
import 'dart:convert';
import 'dart:io';

import 'package:banks/plugin.dart';
import 'package:banks/banks.dart';
import 'package:banks/files.dart';

void main(List<String> args) {
  String? outDir;
  String? extraFile;
  final files = <String>[];
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--out':
        outDir = args[++i];
      case '--extra':
        extraFile = args[++i];
      default:
        files.add(args[i]);
    }
  }
  if (outDir == null || files.isEmpty) {
    stderr.writeln('Usage: dart run banks:anonymize --out <dir> [--extra <file>] <statement.pdf> ...');
    exitCode = 64;
    return;
  }
  final extra = extraFile == null ? <String>[] : File(extraFile).readAsLinesSync();
  Directory(outDir).createSync(recursive: true);

  for (final path in files) {
    final name = path.split(RegExp(r'[\/]')).last;
    try {
      final input = loadStatementInput(path);
      final found = detectStatement(input);
      if (found == null) throw const FormatException('not recognized by any registered bank');
      final (bank, format) = found;
      final original = bank.read(input);
      if (!original.isValid) throw const FormatException('original statement fails its checks');
      final anon = bank.anonymize(input, extra: extra);
      final copy = bank.read(anon);
      if (fingerprint(copy) != fingerprint(original)) {
        throw const FormatException('anonymized copy reads differently from the original');
      }
      final base = '$outDir/$format-${original.periodEnd.toIso8601String().substring(0, 7)}.anon';
      final file = switch (anon) {
        PdfInput(:final words) => File(
          '$base.json',
        )..writeAsStringSync(jsonEncode({'format': format, 'anonymized': true, ...words.toJson()})),
        TextInput(:final text, :final fileType) => File('$base.$fileType')..writeAsStringSync(text),
      };
      stdout.writeln('$name -> ${file.path}  ${summarize(copy)}');
    } on Exception catch (e) {
      exitCode = 1;
      stdout.writeln('$name: SKIPPED $e');
    }
  }
}
