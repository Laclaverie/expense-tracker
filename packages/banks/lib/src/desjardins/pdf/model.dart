/// Parsed Desjardins statements. Amounts are integer cents.
library;

import 'text.dart';

/// One self-check of a statement against its own declared figures.
class Check {
  const Check(this.name, this.expected, this.actual, {this.detail = ''});

  final String name;
  final int expected;
  final int actual;
  final String detail;

  bool get ok => expected == actual;

  @override
  String toString() =>
      '${ok ? 'OK  ' : 'FAIL'} $name: expected ${formatCents(expected)}, '
      'got ${formatCents(actual)}${detail.isEmpty ? '' : ' ($detail)'}';
}

sealed class Statement {
  List<Check> get checks;

  bool get isValid => checks.every((c) => c.ok);
}

// ------------------------------------------------------------------ account

/// Monthly account statement ("Relevé de compte"): one or more sections, each
/// an account (`EOP` checking, `ET 1` savings, `ET 2` TFSA, `CS` member share).
class AccountStatement extends Statement {
  AccountStatement({required this.periodStart, required this.periodEnd, required this.sections});

  final DateTime periodStart;
  final DateTime periodEnd;
  final List<AccountSection> sections;

  AccountSection? section(String id) => sections.where((s) => s.id == id).firstOrNull;

  /// Every line's printed running balance must equal the previous balance
  /// minus fee and withdrawal plus deposit.
  @override
  List<Check> get checks => [
    for (final s in sections)
      for (final (i, l) in s.lines.indexed)
        if (l.balance != null)
          Check(
            '${s.id} line ${i + 1} balance',
            l.balance!,
            s.balanceBefore(i) + l.amount,
            detail: '${l.date.toIso8601String().substring(0, 10)} ${l.code} ${l.description}',
          ),
  ];
}

class AccountSection {
  AccountSection({required this.id, required this.name, required this.opening});

  /// `EOP`, `ET 1`, `ET 2`, `CS`.
  final String id;
  final String name;

  /// "Solde reporté".
  final int opening;
  final List<AccountLine> lines = [];

  /// Balance before line [index], from the last printed balance (or opening).
  int balanceBefore(int index) {
    var balance = opening;
    for (final l in lines.take(index)) {
      balance = l.balance ?? balance + l.amount;
    }
    return balance;
  }

  int get closing => lines.isEmpty ? opening : balanceBefore(lines.length - 1) + lines.last.amount;
}

class AccountLine {
  AccountLine({required this.date, required this.code, required this.description});

  final DateTime date;

  /// Transaction code: `ACH`, `DI`, `RA`, `VMW`, `VIW`, `PWW`, `FIX`, `IET`…
  final String code;
  String description;
  int fee = 0;
  int withdrawal = 0;
  int deposit = 0;

  /// Running balance printed on the line, when present.
  int? balance;

  /// Signed: negative = money out.
  int get amount => deposit - withdrawal - fee;

  @override
  String toString() => '${date.toIso8601String().substring(0, 10)} $code $description ${formatCents(amount)}';
}

// --------------------------------------------------------------------- card

enum CardSection {
  /// "Transactions effectuées avec la carte de …": purchases and refunds.
  purchases,

  /// "Opérations au compte": payments, rewards credits, fees.
  operations,
}

/// Amount in the original currency when the bank converted it.
class ForeignAmount {
  const ForeignAmount(this.cents, this.currency, this.rate);

  final int cents;

  /// ISO code when known (`USD`), otherwise the statement's wording.
  final String currency;

  /// Rate as printed, e.g. `1.422158`.
  final String rate;
}

/// Monthly Odyssée World Elite Mastercard statement.
class CardStatement extends Statement {
  CardStatement({
    required this.statementDate,
    required this.accountNumber,
    required this.summary,
    required this.lines,
    required this.cardTotals,
  });

  final DateTime statementDate;

  /// Last 4 digits of the card account number (`5598 28** **** 3000`).
  final String accountNumber;

  /// Declared figures from the summary: `previousBalance`, `purchases`,
  /// `cashAdvances`, `creditFees`, `installment`, `payments`, `newBalance`.
  final Map<String, int> summary;
  final List<CardLine> lines;

  /// `TOTAL` printed at the end of each card's purchases, by card number.
  final Map<String, int> cardTotals;

  int _sum(Iterable<CardLine> ls) => ls.fold(0, (s, l) => s + l.amount);

  @override
  List<Check> get checks {
    final debits = -_sum(lines.where((l) => !l.isCredit));
    final credits = _sum(lines.where((l) => l.isCredit));
    final s = summary;
    return [
      for (final MapEntry(key: card, value: total) in cardTotals.entries)
        Check(
          'card $card TOTAL',
          total,
          -_sum(lines.where((l) => l.card == card && l.section == CardSection.purchases)),
        ),
      Check('debits = Achats / débits', s['purchases'] ?? 0, debits),
      Check('credits = Paiements / crédits', s['payments'] ?? 0, credits),
      Check(
        'new balance',
        s['newBalance'] ?? 0,
        (s['previousBalance'] ?? 0) +
            (s['purchases'] ?? 0) +
            (s['cashAdvances'] ?? 0) +
            (s['creditFees'] ?? 0) +
            (s['installment'] ?? 0) -
            (s['payments'] ?? 0),
      ),
    ];
  }
}

class CardLine {
  CardLine({
    required this.card,
    required this.section,
    required this.transactionDate,
    required this.postedDate,
    required this.description,
    required this.location,
    required this.amount,
    required this.isCredit,
    this.bonusRate,
  });

  /// Last 4 digits of the card used (`3026`); account number for operations.
  final String card;
  final CardSection section;
  final DateTime transactionDate;
  final DateTime postedDate;
  final String description;

  /// City and province (`MONTREAL QC`), phone or web site; may be empty.
  final String location;

  /// Signed from the cardholder's point of view: purchase negative, credit positive.
  final int amount;
  final bool isCredit;

  /// Bonidollars rate in basis points (300 = 3,00 %), a hint of the bank's category.
  final int? bonusRate;
  ForeignAmount? foreign;

  @override
  String toString() =>
      '${transactionDate.toIso8601String().substring(0, 10)} $description | $location | ${formatCents(amount)}';
}
