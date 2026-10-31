import 'dart:io';

import 'package:expense_desktop/statement_reader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads real statement PDFs from a local folder (never committed):
///   EXPENSES_STATEMENTS=E:\path\to\pdfs flutter test test/statement_reader_test.dart
void main() {
  final dir = Platform.environment['EXPENSES_STATEMENTS'];
  test('reads and validates real statements in a background isolate', () async {
    final pdfs = Directory(dir!).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.pdf'));
    expect(pdfs, isNotEmpty);
    for (final f in pdfs) {
      final read = await readStatementFile(f.path);
      expect(read.statement.isValid, isTrue, reason: f.path);
      expect(read.fileHash, hasLength(64));
    }
  }, skip: dir == null ? 'set EXPENSES_STATEMENTS to a folder of statement PDFs' : false);
}
