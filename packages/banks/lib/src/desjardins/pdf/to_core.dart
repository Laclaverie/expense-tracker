import 'package:banks/plugin.dart';

import 'model.dart';

/// Converts a parsed Desjardins statement into the bank-neutral import
/// format, deciding each line's kind and category hint from Desjardins codes.
ImportedStatement toImported(Statement statement) => switch (statement) {
  AccountStatement() => _account(statement),
  CardStatement() => _card(statement),
};

List<String> _failed(Statement s) => [
  for (final c in s.checks)
    if (!c.ok) c.toString(),
];

// ------------------------------------------------------------------ account

ImportedStatement _account(AccountStatement s) {
  final classifier = LineClassifier(accountRules);
  final lines = [
    for (final section in s.sections)
      for (final l in section.lines) _accountLine(section.id, l, classifier),
  ];
  return ImportedStatement(
    institution: 'desjardins',
    format: 'desjardins-account',
    periodStart: s.periodStart,
    periodEnd: s.periodEnd,
    accounts: [
      for (final section in s.sections)
        ImportedAccount(
          ref: section.id,
          name: _sentenceCase(section.name),
          type: _accountType(section),
          currency: 'CAD',
          closingBalance: section.closing,
        ),
    ],
    lines: lines,
    failedChecks: _failed(s),
    checkCount: s.checks.length,
    warnings: classifier.warnings,
  );
}

/// `COMPTE POUR PROFESSIONNELS` -> `Compte pour professionnels`; mixed case kept.
String _sentenceCase(String s) => s != s.toUpperCase() || s.isEmpty ? s : s[0] + s.substring(1).toLowerCase();

AccountType _accountType(AccountSection s) => switch (s.id) {
  'EOP' => AccountType.checking,
  'CS' => AccountType.share,
  _ when s.name.contains('CELI') || s.name.contains('REER') => AccountType.registered,
  _ => AccountType.savings,
};

/// `Achat / LA BUCHE` -> `LA BUCHE`; `Virement Interac à / NAME/` -> `NAME`.
String _counterparty(String description) {
  final slash = description.indexOf(' / ');
  if (slash < 0) return description;
  final rest = description.substring(slash + 3).trim();
  final end = rest.indexOf(' /'); // `Name /Loyer`
  return (end > 0 ? rest.substring(0, end) : rest).replaceAll(RegExp(r'/$'), '').trim();
}

/// Account statement codes, most specific rows first (see [LineRule]). A code
/// missing here is reported by `banks:parse` and fails the fixture tests.
const accountRules = [
  // Between own accounts: online, manual, automatic transfer, account opening deposit, ATM deposit.
  LineRule(
    codes: {'VIW', 'VIM', 'VIR', 'OUV', 'IDGA'},
    kind: TransactionKind.transfer,
    hint: 'excluded.internal_transfer',
  ),
  LineRule(codes: {'PWW'}, contains: 'Mastercard', kind: TransactionKind.transfer, hint: 'excluded.card_payment'),
  LineRule(codes: {'PWW'}, contains: 'Odyssée', kind: TransactionKind.transfer, hint: 'excluded.card_payment'),
  LineRule(codes: {'PWW'}, kind: TransactionKind.expense), // other bill payments
  // ATM withdrawals (Desjardins, other networks): the cash wallet is credited.
  LineRule(codes: {'IRGA', 'RGA', 'RGP'}, kind: TransactionKind.transfer, hint: 'excluded.cash_withdrawal'),
  LineRule(codes: {'FIX', 'FCR', 'DT', 'ADM'}, kind: TransactionKind.fee, hint: 'finance.bank_fees'),
  LineRule(codes: {'CDT'}, kind: TransactionKind.refund, hint: 'finance.bank_fees'),
  LineRule(codes: {'IET', 'INT', 'BNI'}, kind: TransactionKind.interest, hint: 'income.interest'),
  // Mobile deposit, member dividend ("ristourne").
  LineRule(codes: {'DMD', 'RIS'}, kind: TransactionKind.income, hint: 'income.other'),
  LineRule(codes: {'DI'}, startsWith: 'Paie', kind: TransactionKind.income, hint: 'income.salary'),
  LineRule(codes: {'DI'}, contains: 'impôt', kind: TransactionKind.income, hint: 'income.tax_refund'),
  LineRule(codes: {'DI'}, contains: 'Assurance', kind: TransactionKind.income, hint: 'income.insurance_refund'),
  LineRule(codes: {'DI'}, kind: TransactionKind.income, hint: 'income.other'),
  // Interac between people (IVMW: older statements, money received).
  LineRule(codes: {'VMW'}, startsWith: 'Annulation', kind: TransactionKind.refund, hint: 'people.sent', isPerson: true),
  LineRule(
    codes: {'VMW'},
    contains: '/Loyer',
    direction: Direction.moneyOut,
    kind: TransactionKind.expense,
    hint: 'housing.rent',
    isPerson: true,
  ),
  LineRule(
    codes: {'VMW'},
    direction: Direction.moneyOut,
    kind: TransactionKind.expense,
    hint: 'people.sent',
    isPerson: true,
  ),
  LineRule(codes: {'VMW', 'IVMW'}, kind: TransactionKind.income, hint: 'income.reimbursements', isPerson: true),
  // Purchases (debit card, pre-authorized), direct debits (insurance, government), returned payments.
  LineRule(codes: {'ACH', 'APA', 'RA'}, direction: Direction.moneyOut, kind: TransactionKind.expense),
  LineRule(codes: {'ACH', 'APA', 'RA', 'CRM'}, direction: Direction.moneyIn, kind: TransactionKind.refund),
];

ImportedLine _accountLine(String accountRef, AccountLine l, LineClassifier classifier) {
  final c = classifier.classify(code: l.code, description: l.description, amount: l.amount);
  return ImportedLine(
    accountRef: accountRef,
    date: l.date,
    amount: l.amount,
    description: l.description,
    code: l.code,
    kind: c.kind,
    categoryHint: c.hint,
    merchantText: _counterparty(l.description),
    isPerson: c.isPerson,
  );
}

// --------------------------------------------------------------------- card

ImportedStatement _card(CardStatement s) {
  final ref = 'card-${s.accountNumber}';
  final classifier = LineClassifier(cardRules);
  final lines = [for (final l in s.lines) _cardLine(ref, l, classifier)];
  return ImportedStatement(
    institution: 'desjardins',
    format: 'desjardins-card',
    // Only the statement date is printed: it covers the days since the previous one.
    periodStart: s.statementDate.subtract(const Duration(days: 30)),
    periodEnd: s.statementDate,
    coversSincePrevious: true,
    accounts: [
      ImportedAccount(
        ref: ref,
        name: 'Odyssée World Elite Mastercard',
        type: AccountType.creditCard,
        currency: 'CAD',
        closingBalance: s.summary['newBalance'] == null ? null : -s.summary['newBalance']!,
      ),
    ],
    lines: lines,
    failedChecks: _failed(s),
    checkCount: s.checks.length,
    warnings: classifier.warnings,
  );
}

/// Card statement lines by section (no codes on card statements).
const cardRules = [
  LineRule(
    section: 'operations',
    startsWith: 'PAIEMENT',
    kind: TransactionKind.transfer,
    hint: 'excluded.card_payment',
  ),
  LineRule(section: 'operations', contains: 'BONIDOLLARS', kind: TransactionKind.income, hint: 'income.rewards'),
  LineRule(section: 'operations', contains: 'INTÉR', kind: TransactionKind.fee, hint: 'finance.interest_paid'),
  LineRule(section: 'operations', contains: 'INTER', kind: TransactionKind.fee, hint: 'finance.interest_paid'),
  LineRule(section: 'operations', contains: 'FRAIS', kind: TransactionKind.fee, hint: 'finance.bank_fees'),
  LineRule(section: 'purchases', direction: Direction.moneyOut, kind: TransactionKind.expense),
  LineRule(section: 'purchases', direction: Direction.moneyIn, kind: TransactionKind.refund),
];

ImportedLine _cardLine(String ref, CardLine l, LineClassifier classifier) {
  final c = classifier.classify(section: l.section.name, description: l.description, amount: l.amount);
  return ImportedLine(
    accountRef: ref,
    date: l.transactionDate,
    postedDate: l.postedDate,
    amount: l.amount,
    description: l.description,
    kind: c.kind,
    categoryHint: c.hint,
    merchantText: l.description,
    location: l.location.isEmpty ? null : l.location,
    bonusRate: l.bonusRate,
    foreignCents: l.foreign?.cents,
    foreignCurrency: l.foreign?.currency,
    fxRate: l.foreign?.rate,
    card: l.card,
  );
}
