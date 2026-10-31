/// Every bank the app can import statements from. Each bank is a plug-in in
/// `lib/src/<bank>/`; adding one = a folder plus one entry in [banks] (see
/// `docs/10-adding-a-bank.md`).
library;

import 'plugin.dart';
import 'src/desjardins/importer.dart';

export 'plugin.dart' show BankImporter, PdfInput, StatementFormat, StatementInput, TextInput, statementFileTypes;

/// Registered plug-ins, in the order they try to recognize a file.
const List<BankImporter> banks = [
  // One line per bank, in alphabetical order:
  DesjardinsImporter(),
];

/// The plug-in for [institution] (`desjardins`), if registered.
BankImporter? bankFor(String institution) => banks.where((b) => b.institution == institution).firstOrNull;

/// The statement format [id] (`desjardins-card`) of any registered bank.
StatementFormat? statementFormat(String id) {
  for (final b in banks) {
    final f = b.format(id);
    if (f != null) return f;
  }
  return null;
}

/// The bank and format that recognize [input], if any.
(BankImporter, String)? detectStatement(StatementInput input) {
  for (final b in banks) {
    final format = b.detect(input);
    if (format != null) return (b, format);
  }
  return null;
}

/// Reads [input] with the bank that recognizes it. Throws [FormatException]
/// when no registered bank does.
ImportedStatement readStatement(StatementInput input) {
  final found = detectStatement(input);
  if (found == null) {
    throw FormatException(
      'Not a recognized statement. Supported: ${[for (final b in banks) b.displayName].join(', ')}',
    );
  }
  return found.$1.read(input);
}
