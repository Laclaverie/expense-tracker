/// What the made-up household did, bank-neutral: money moves on accounts
/// and card lines. Bank writers (`desjardins/`) lay it out as statements.
library;

/// A line on a bank account (checking, savings, TFSA).
class AccountEntry {
  AccountEntry(this.account, this.date, this.code, this.description, this.amount);

  /// `EOP` (checking), `ET 1` (savings), `ET 2` (TFSA).
  final String account;
  final DateTime date;

  /// Desjardins transaction code (`DI`, `VMW`, `PWW`…): the plug-in's rules
  /// table decides each line's kind from it.
  final String code;
  final String description;

  /// Signed cents: negative = money out.
  final int amount;
}

/// Amount in a foreign currency, as the card network converted it.
class Foreign {
  const Foreign(this.cents, this.currency, this.rate);

  final int cents;

  /// ISO code: `USD`.
  final String currency;
  final double rate;
}

/// A line on the credit card account.
class CardEntry {
  CardEntry({
    required this.date,
    required this.posted,
    required this.card,
    required this.merchant,
    this.location = '',
    required this.amount,
    this.operation = false,
    this.bonusRate,
    this.foreign,
    this.category,
  });

  final DateTime date;
  final DateTime posted;

  /// Last 4 digits of the card used; the account number for operations.
  final String card;
  final String merchant;

  /// `MONTREAL QC`, or a word without region (`Internet`), or empty.
  final String location;

  /// Signed cents from the holder's side: purchase negative, credit positive.
  final int amount;

  /// Payments, rewards, annual fee: printed apart from purchases.
  final bool operation;

  /// Rewards rate in basis points (300 = 3 %), printed by older layouts.
  final int? bonusRate;
  final Foreign? foreign;

  /// The category the household would give it (the demo database confirms
  /// it, as if reviewed). Null: left to the app.
  final String? category;
}

/// Two years of the household's money, plus what the writers need around it.
class Life {
  Life({
    required this.accountEntries,
    required this.cardEntries,
    required this.openings,
    required this.cardStatementDates,
    required this.accountCategories,
  });

  final List<AccountEntry> accountEntries;
  final List<CardEntry> cardEntries;

  /// Balance of each account (`EOP`, `ET 1`, `ET 2`, `CS`) before the first entry.
  final Map<String, int> openings;

  /// Closing dates of the card statements, oldest first.
  final List<DateTime> cardStatementDates;

  /// Category the household gives account lines, by counterparty (`Hydro-Québec`).
  final Map<String, String> accountCategories;
}
