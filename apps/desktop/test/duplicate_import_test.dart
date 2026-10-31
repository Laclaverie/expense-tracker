import 'dart:io';

import 'package:drift/native.dart';
import 'package:expense_desktop/statement_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

/// Real PDFs, local only:
///   EXPENSES_STATEMENTS=E:\path\to\pdfs flutter test test/duplicate_import_test.dart
void main() {
  final dir = Platform.environment['EXPENSES_STATEMENTS'];
  test('a renamed copy of an imported PDF is recognized', () async {
    final pdf = Directory(dir!).listSync(recursive: true).whereType<File>().firstWhere((f) => f.path.endsWith('.pdf'));
    final copy = File('${Directory.systemTemp.createTempSync('dup').path}${Platform.pathSeparator}renamed.pdf');
    pdf.copySync(copy.path);
    final db = ExpenseDatabase(NativeDatabase.memory());
    final importer = ImportService(db);
    try {
      final first = await readStatementFile(pdf.path);
      expect(
        (await importer.importStatement(first.statement, fileHash: first.fileHash, fileName: 'a.pdf')).status,
        ImportStatus.imported,
      );
      final again = await readStatementFile(copy.path);
      final r = await importer.importStatement(again.statement, fileHash: again.fileHash, fileName: 'renamed.pdf');
      expect(
        (r.status, r.duplicateReason, r.existing?.fileName),
        (ImportStatus.alreadyImported, DuplicateReason.sameFile, 'a.pdf'),
      );
    } finally {
      await db.close();
      copy.parent.deleteSync(recursive: true);
    }
  }, skip: dir == null ? 'set EXPENSES_STATEMENTS to a folder of statement PDFs' : false);
}
