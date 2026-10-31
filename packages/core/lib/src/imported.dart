import 'kind.dart';

/// Bank-neutral result of reading one statement file. Each bank's import
/// package converts its parsed statements into this.
class ImportedStatement {
  ImportedStatement({
    required this.institution,
    required this.format,
    required this.periodStart,
    required this.periodEnd,
    required this.accounts,
    required this.lines,
    required this.failedChecks,
    required this.checkCount,
    this.coversSincePrevious = false,
    this.warnings = const [],
  });

  /// The bank plug-in's id: `desjardins`.
  final String institution;

  /// `<institution>-<kind>`: `desjardins-account`, `desjardins-card`.
  final String format;
  final DateTime periodStart;
  final DateTime periodEnd;

  /// The statement only prints its closing date ([periodEnd]): it covers the
  /// days since the previous statement of the same format, and [periodStart]
  /// is an estimate (credit cards often work like this).
  final bool coversSincePrevious;
  final List<ImportedAccount> accounts;
  final List<ImportedLine> lines;

  /// Human-readable descriptions of failed self-checks. Empty = valid.
  final List<String> failedChecks;
  final int checkCount;

  /// Things the plug-in wasn't sure about but that don't refuse the import,
  /// e.g. transaction codes no rule maps (see `LineClassifier`). No personal data.
  final List<String> warnings;

  bool get isValid => failedChecks.isEmpty;
}

class ImportedAccount {
  const ImportedAccount({
    required this.ref,
    required this.name,
    required this.type,
    required this.currency,
    this.closingBalance,
  });

  /// Stable reference inside the institution: `EOP`, `ET 1`, `card-0001`.
  final String ref;
  final String name;
  final AccountType type;
  final String currency;

  /// Balance at the end of the statement, when known (cents).
  final int? closingBalance;
}

class ImportedLine {
  ImportedLine({
    required this.accountRef,
    required this.date,
    required this.amount,
    required this.description,
    required this.kind,
    required this.merchantText,
    this.postedDate,
    this.code,
    this.location,
    this.bonusRate,
    this.foreignCents,
    this.foreignCurrency,
    this.fxRate,
    this.card,
    this.categoryHint,
    this.isPerson = false,
  });

  final String accountRef;
  final DateTime date;
  final DateTime? postedDate;

  /// Signed cents, account currency. Negative = money out.
  final int amount;

  /// Exactly as on the statement.
  final String description;

  /// Bank transaction code (`ACH`, `VMW`…), when the bank has codes.
  final String? code;
  final TransactionKind kind;

  /// The part of the description naming the merchant or counterparty.
  final String merchantText;
  final String? location;

  /// Card reward rate in basis points (e.g. Desjardins Bonidollars), when the
  /// statement prints one per line — used as a category hint.
  final int? bonusRate;
  final int? foreignCents;
  final String? foreignCurrency;
  final String? fxRate;

  /// Card used (last 4 digits) for card statements.
  final String? card;

  /// Category the bank's format implies (fees, salary, card payment…).
  final String? categoryHint;

  /// Money sent to or received from a person (Interac transfer), not a
  /// business: kept out of merchant rankings.
  final bool isPerson;
}
