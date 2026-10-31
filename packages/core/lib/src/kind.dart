/// What a transaction is, which decides whether it counts as spending.
enum TransactionKind {
  /// Money spent: purchase, bill, rent, money sent to people.
  expense,

  /// Money received: salary, tax refund, reimbursement, rewards.
  income,

  /// Money back for an earlier expense (merchant refund, cancelled transfer).
  refund,

  /// Bank fees.
  fee,

  /// Interest earned.
  interest,

  /// Between two accounts of the same institution (checking ↔ savings,
  /// card payment, ATM withdrawal to the cash wallet).
  transfer,

  /// To or from another institution (Desjardins ↔ LCL). Not linked to the
  /// other side — accepted limitation.
  externalTransfer;

  /// Spending stats include expenses and fees, net of refunds.
  bool get countsAsSpending => this == expense || this == fee || this == refund;

  bool get countsAsIncome => this == income || this == interest;

  bool get isTransfer => this == transfer || this == externalTransfer;
}

enum AccountType { checking, savings, registered, share, creditCard, cash }
