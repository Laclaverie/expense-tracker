/// The contract between the app and a bank plug-in: detect a statement,
/// read it into the bank-neutral [ImportedStatement], anonymize it for test
/// fixtures. See `docs/10-adding-a-bank.md`.
///
/// Fixture tests: `package:banks/testing.dart`.
library;

export 'package:core/core.dart'
    show AccountType, ImportedAccount, ImportedLine, ImportedStatement, TransactionKind, defaultCategories;
export 'package:pdf_words/pdf_words.dart';

export 'src/plugin/anonymize.dart';
export 'src/plugin/csv.dart';
export 'src/plugin/importer.dart';
export 'src/plugin/input.dart';
export 'src/plugin/rules.dart';
export 'src/plugin/summary.dart';
export 'src/plugin/words.dart';
