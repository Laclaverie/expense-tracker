import 'package:core/core.dart';

import 'input.dart';
import 'rules.dart';

/// One kind of statement a bank produces: a checking account statement, a
/// credit card statement… whatever file type it comes in.
class StatementFormat {
  const StatementFormat({
    required this.id,
    required this.labelFr,
    required this.labelEn,
    required this.accountType,
    this.fileTypes = const {'pdf'},
    this.uncheckedFileTypes = const {},
  });

  /// Stored with each imported statement: `<institution>-<kind>`, e.g.
  /// `desjardins-card`. Never change it once statements were imported. The
  /// same statement read from a PDF or from a CSV export keeps the same id, so
  /// both count for the same months.
  final String id;

  /// File types this plug-in reads the statement from: `pdf`, `csv`, `ofx`…
  final Set<String> fileTypes;

  /// File types of [fileTypes] with nothing to check lines against (no
  /// balance, no totals): read with `checkCount` 0, shown as not verified.
  /// Every other file type needs at least one self-check.
  final Set<String> uncheckedFileTypes;

  /// Short name in sentences such as "Mastercard statement missing".
  final String labelFr;
  final String labelEn;

  /// The main kind of account the statement lists (picks the icon).
  final AccountType accountType;

  String label(String languageCode) => languageCode == 'fr' ? labelFr : labelEn;
}

/// A bank plug-in. Implementations are pure Dart (no Flutter), stateless and
/// registered in `packages/banks/lib/banks.dart`.
abstract class BankImporter {
  const BankImporter();

  /// Stable id stored in the database (`desjardins`, `lcl`). Lower case, no
  /// spaces. Never change it once statements were imported.
  String get institution;

  /// Shown in the app (`Desjardins`).
  String get displayName;

  /// ISO country code, informational (`CA`, `FR`).
  String get country;

  /// Every statement format [detect] can return.
  List<StatementFormat> get formats;

  /// The format id when [input] is one of this bank's statements, otherwise
  /// null. Called on every imported file for every bank: look at the input's
  /// type first (`switch (input) { PdfInput() => …, TextInput(fileType: 'csv') => …, _ => null }`),
  /// keep it cheap (first page, header line) and never throw.
  String? detect(StatementInput input);

  /// Reads a statement [detect] recognized. Self-checks (running balances,
  /// totals printed by the bank) go in [ImportedStatement.failedChecks]: the
  /// app refuses a statement that fails one. Throws [FormatException] when the
  /// file can't be read at all.
  ImportedStatement read(StatementInput input);

  /// A copy of [input], same type, safe to commit as a test fixture: names,
  /// addresses, account / card / contract numbers, people's names and every
  /// word of [extra] replaced; layout, dates and amounts kept. Must end with
  /// `verifyAnonymized` / `verifyTextAnonymized` so a leak throws instead of
  /// being written.
  StatementInput anonymize(StatementInput input, {Iterable<String> extra = const []});

  StatementFormat? format(String id) => formats.where((f) => f.id == id).firstOrNull;

  /// How to download the bank's export (CSV, OFX…) when it has one: shown in
  /// the app's list of supported banks and after a PDF import of this bank,
  /// since an export is more reliable than reading PDFs. Null = none.
  ExportGuide? get exportGuide => null;

  /// The bank's classification tables ([LineRule]): their wording (`Paie`,
  /// `Virement Interac`) is the bank's, not anyone's data, so an anonymized
  /// developer copy keeps those words (storage `writeDevCopy`).
  List<LineRule> get lineRules => const [];
}

/// Steps to download a bank's export, for people who never did it.
class ExportGuide {
  const ExportGuide({
    required this.fileType,
    required this.stepsFr,
    required this.stepsEn,
    this.notesFr = '',
    this.notesEn = '',
    this.images = const {},
  });

  /// `csv`, `ofx`…
  final String fileType;

  /// One sentence per step, in order.
  final List<String> stepsFr, stepsEn;

  /// Limits worth knowing (how far back, how often).
  final String notesFr, notesEn;

  /// Screenshots by step number (1 = first step): file names in the app's
  /// `assets/guides/<institution>/`, with names and account numbers hidden
  /// before they are committed.
  final Map<int, String> images;

  List<String> steps(String languageCode) => languageCode == 'fr' ? stepsFr : stepsEn;
  String notes(String languageCode) => languageCode == 'fr' ? notesFr : notesEn;
}
