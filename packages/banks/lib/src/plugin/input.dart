import 'dart:convert';

import 'package:pdf_words/pdf_words.dart';

/// A statement file as a plug-in sees it, already decoded by the app according
/// to its file type: words with coordinates for a PDF, text for a CSV / OFX /
/// QIF / TXT export. Plug-ins never read files themselves.
sealed class StatementInput {
  const StatementInput(this.fileName);

  /// Original file name, for messages only (`releve-2026-09.pdf`).
  final String fileName;

  /// Lower-case file type without the dot: `pdf`, `csv`, `ofx`…
  String get fileType;
}

/// A PDF statement: every word with its position (see `pdf_words`).
class PdfInput extends StatementInput {
  const PdfInput(super.fileName, this.words);

  final DocumentWords words;

  @override
  String get fileType => 'pdf';
}

/// A text export (CSV, OFX, QIF, TXT…), decoded as UTF-8 (or Windows-1252 /
/// Latin-1 when it isn't valid UTF-8), without byte-order mark.
class TextInput extends StatementInput {
  const TextInput(super.fileName, this.text, {required this.fileType});

  final String text;

  @override
  final String fileType;

  /// Non-empty lines, line endings normalized.
  List<String> get lines => [
    for (final l in text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n'))
      if (l.trim().isNotEmpty) l,
  ];
}

/// File types the app hands to plug-ins. Anything else is refused before any
/// plug-in sees it.
const statementFileTypes = {'pdf', 'csv', 'ofx', 'qfx', 'qif', 'txt'};

/// Text of an exported file: UTF-8 when valid, otherwise Windows-1252 / Latin-1
/// (what many banks still produce); byte-order mark removed.
String decodeStatementText(List<int> bytes) {
  final body = bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF ? bytes.sublist(3) : bytes;
  try {
    return utf8.decode(body);
  } on FormatException {
    return latin1.decode(body);
  }
}
