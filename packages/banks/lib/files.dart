/// Turns a file on disk into the [StatementInput] plug-ins get, by file type.
/// Used by the app, the command-line tools and the demo database tool.
library;

import 'dart:convert';
import 'dart:io';

import 'package:pdf_words/pdfium.dart';

import 'plugin.dart';

/// [loadStatementInput] for the command-line tools: a file that can't be read
/// (damaged or scanned PDF, unknown type) prints one line instead of a stack
/// trace, sets a failing exit code and returns null.
StatementInput? loadOrReport(String path) {
  try {
    return loadStatementInput(path);
  } on Object catch (e) {
    stderr.writeln('Cannot read ${path.split(RegExp(r'[\\/]')).last}: ${e is FormatException ? e.message : e}');
    exitCode = 1;
    return null;
  }
}

/// `.pdf` → [PdfInput] (words extracted with PDFium); `.json` → [PdfInput] from
/// a word dump (fixtures, `banks:dump --json`); a text export (`.csv`, `.ofx`…)
/// → [TextInput]. Throws [FormatException] for other file types.
StatementInput loadStatementInput(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final type = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  if (type == 'json') {
    return PdfInput(name, DocumentWords.fromJson(jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>));
  }
  if (!statementFileTypes.contains(type)) {
    throw FormatException('Unsupported file type .$type (supported: ${statementFileTypes.join(', ')})', name);
  }
  if (type == 'pdf') return PdfInput(name, extractWords(path));
  return TextInput(name, decodeStatementText(File(path).readAsBytesSync()), fileType: type);
}

/// [paths] with every folder replaced by the statement files in it and its
/// subfolders (sorted, word dumps included), leaving out what the tools write
/// next to statements (`*.shape.txt`, `*.dump.txt`, `reveal.txt`, an
/// `anonymized` folder…): the command-line tools take folders.
List<String> expandStatementPaths(List<String> paths) => [
  for (final p in paths)
    if (FileSystemEntity.isDirectorySync(p))
      ...(Directory(p).listSync(recursive: true).whereType<File>().map((f) => f.path).where((f) {
        final parts = f.split(RegExp(r'[\\/]'));
        final name = parts.last.toLowerCase();
        final type = name.contains('.') ? name.split('.').last : '';
        if (parts.contains('anonymized') || _toolOutput.any(name.endsWith)) return false;
        return statementFileTypes.contains(type) || type == 'json'; // json: word dumps, fixtures
      }).toList()..sort())
    else
      p,
];

const _toolOutput = ['.shape.txt', '.shape.json', '.dump.txt', 'reveal.txt', 'notes.txt', 'readme.txt', 'extra.txt'];
