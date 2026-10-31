/// Tests every bank plug-in should run on its fixtures:
///
/// ```dart
/// void main() => testFixtures(const MyBankImporter(), 'test/fixtures');
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:pdf_words/pdf_words.dart';
import 'package:test/test.dart';

import 'src/plugin/importer.dart';
import 'src/plugin/input.dart';

/// A fixture file: synthetic (`*.synthetic.json`, written by `dart run
/// demo:fixtures` from a made-up household) or an anonymized real statement
/// (`*.anon.json`, `*.anon.csv`…, written by `dart run banks:anonymize`; only
/// the synthetic ones are committed).
bool isFixture(String path) => path.contains('.synthetic.') || path.contains('.anon.');

/// Loads a fixture ([isFixture]): a PDF word dump (`.json`) or a text export
/// (`.csv`, `.ofx`…).
StatementInput loadFixture(String path) {
  final file = File(path);
  final name = file.uri.pathSegments.last;
  final type = name.split('.').last;
  if (type == 'json') {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    if (json['anonymized'] != true && json['synthetic'] != true) {
      throw StateError('$name: not written by banks:anonymize or demo:fixtures');
    }
    return PdfInput(name, DocumentWords.fromJson(json));
  }
  return TextInput(name, decodeStatementText(file.readAsBytesSync()), fileType: type);
}

/// For every fixture in [directory] ([isFixture]): it comes from
/// `demo:fixtures` or `banks:anonymize`, [importer] detects the format named in
/// its file name (`<format>-YYYY-MM.<synthetic|anon>.<type>`) and lists its
/// file type,
/// reads it, every self-check passes, no line falls outside the rules table
/// (no warnings), and the result is consistent (lines
/// belong to declared accounts, amounts non-zero, categories exist, dates
/// inside a sane window around the period).
void testFixtures(BankImporter importer, String directory) {
  final files = Directory(directory).listSync().whereType<File>().where((f) => isFixture(f.path)).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  test('$directory has fixtures', () => expect(files, isNotEmpty));
  final categories = {for (final c in defaultCategories) c.id};
  group('${importer.institution} fixtures', () {
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      test(name, () {
        final input = loadFixture(f.path);
        final format = importer.detect(input);
        expect(format, isNotNull, reason: 'detect() must recognize its own fixture');
        expect(name, startsWith('$format-'), reason: 'fixture names start with the format id');
        expect(importer.format(format!), isNotNull, reason: 'format $format missing from formats');
        expect(importer.format(format)!.fileTypes, contains(input.fileType), reason: 'fileTypes of $format');
        final s = importer.read(input);
        expect(s.institution, importer.institution);
        expect(s.format, format);
        expect(s.failedChecks, isEmpty);
        expect(s.warnings, isEmpty, reason: 'map every code / line type in the rules table');
        if (!importer.format(format)!.uncheckedFileTypes.contains(input.fileType)) {
          expect(s.checkCount, greaterThan(0), reason: 'a statement needs self-checks (balances, totals)');
        }
        expect(s.periodStart.isAfter(s.periodEnd), isFalse);
        final refs = {for (final a in s.accounts) a.ref};
        expect(refs, hasLength(s.accounts.length), reason: 'account refs must be unique');
        for (final l in s.lines) {
          expect(refs, contains(l.accountRef));
          expect(l.amount, isNot(0), reason: l.description);
          expect(l.date.isUtc, isTrue);
          expect(l.date.isBefore(s.periodStart.subtract(const Duration(days: 62))), isFalse, reason: '${l.date}');
          expect(l.date.isAfter(s.periodEnd.add(const Duration(days: 1))), isFalse, reason: '${l.date}');
          if (l.categoryHint != null) expect(categories, contains(l.categoryHint));
        }
      });
    }
  });
}
