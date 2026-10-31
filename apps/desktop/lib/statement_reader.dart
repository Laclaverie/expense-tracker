import 'dart:io';
import 'dart:isolate';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:banks/banks.dart' as registry;
import 'package:banks/files.dart';

/// A statement file read and parsed, ready for `ImportService`.
class ReadStatement {
  const ReadStatement(this.statement, this.fileHash);

  final ImportedStatement statement;

  /// SHA-256 of the file content.
  final String fileHash;
}

/// Reads and parses a statement file (PDF, CSV, OFX…) in a background isolate
/// (PDFium + parsing take ~100 ms per file; the UI stays responsive). Throws
/// [FormatException] for files no registered bank recognizes (see `packages/banks`).
Future<ReadStatement> readStatementFile(String path) => Isolate.run(() {
  final hash = sha256.convert(File(path).readAsBytesSync()).toString();
  final statement = registry.readStatement(loadStatementInput(path));
  return ReadStatement(statement, hash);
});
