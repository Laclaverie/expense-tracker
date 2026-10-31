import 'package:banks/plugin.dart';

/// Desjardins CSV exports (AccèsD > Relevés et documents > Télécharger les
/// transactions), no header, comma-separated, dates `YYYY/MM/DD`. One layout
/// for every product: columns a product doesn't use stay `""`.
///
/// | col | account export (16 columns)             | card export (13 columns)       |
/// |-----|-----------------------------------------|--------------------------------|
/// | 1   | caisse name                             | card name + `**** 1234`        |
/// | 2   | folio (account number)                  | empty                          |
/// | 3   | account code (`EOP`, `ET01`, `ET02`)     | empty                          |
/// | 4   | date                                    | date                           |
/// | 5   | sequence number                         | sequence number                |
/// | 6   | description                             | merchant (25) city (13) prov.  |
/// | 7   | cheque number                           | empty                          |
/// | 8–9 | withdrawal, deposit                     | empty                          |
/// | 10–11 | interest, capital (loans): empty      | empty                          |
/// | 12–13 | advance, reimbursement: empty         | purchase, credit               |
/// | 14  | empty                                   | —                              |
/// | 15  | balance after the line                  | —                              |
/// | 16  | Interac message                         | —                              |
///
/// The file holds every account of the export, one block each: days oldest
/// first, the lines of a day newest first. Account lines check against the
/// running balance (which also confirms that order); card lines have
/// nothing to check against (the card's "not verified" file type).
enum DesjardinsCsv { account, card }

final _date = RegExp(r'^\d{4}/\d{2}/\d{2}$');

/// The fields of one export line, split into [columns]. Descriptions aren't
/// quoted: a comma in one (`ACME, INC`) makes extra fields, joined back into
/// the description (column 6).
List<String> desjardinsRow(String line, int columns) {
  final r = splitCsvLine(line);
  if (r.length <= columns) return r;
  final extra = r.length - columns;
  return [...r.take(5), r.sublist(5, 6 + extra).join(','), ...r.skip(6 + extra)];
}

List<List<String>> _rows(TextInput input, int columns) => [for (final l in input.lines) desjardinsRow(l, columns)];

/// Which export [input] is, from its first line; null when it isn't one.
DesjardinsCsv? detectCsv(TextInput input) {
  if (input.fileType != 'csv') return null;
  final lines = input.lines;
  if (lines.isEmpty) return null;
  final first = splitCsvLine(lines.first);
  if (first.length < 13 || !_date.hasMatch(first[3]) || int.tryParse(first[4]) == null) return null;
  final account = desjardinsRow(lines.first, 16), card = desjardinsRow(lines.first, 13);
  if (account.length == 16 && RegExp(r'^\d+$').hasMatch(account[1]) && account[2].isNotEmpty) {
    return DesjardinsCsv.account;
  }
  if (card.length == 13 && card[1].isEmpty && card[2].isEmpty && card[0].contains('****')) return DesjardinsCsv.card;
  return null;
}

DateTime _parseDate(String s, int line) =>
    parseCsvDate(s) ?? (throw FormatException('Desjardins CSV line $line: date expected in column 4'));

/// Cents of a filled amount column, 0 when `""`.
int _cents(List<String> r, int column, int line) {
  final v = r[column - 1].trim();
  if (v.isEmpty) return 0;
  return parseCsvCents(v) ?? (throw FormatException('Desjardins CSV line $line: amount expected in column $column'));
}

/// `ET01` -> `ET 1`: the account refs the PDF account statement uses, so both
/// sources land in the same accounts.
String accountRef(String code) {
  final m = RegExp(r'^([A-Z]+)0*(\d+)$').firstMatch(code);
  return m == null ? code : '${m[1]} ${m[2]}';
}

AccountType _accountType(String ref) => switch (ref) {
  'EOP' => AccountType.checking,
  'CS' => AccountType.share,
  _ => AccountType.savings,
};

String _accountName(String ref) => switch (ref) {
  'EOP' => 'Compte avec opérations',
  'CS' => 'Parts de qualification',
  _ => 'Épargne $ref',
};

/// `Achat /LA BUCHE` -> `LA BUCHE`; `Virement Interac à /NAME/` -> `NAME`;
/// `Virement Interac à /Name /Loyer` -> `Name`; `Virement - AccesD Internet
/// /à 1234567-ET1` -> `à ET 1`; no ` /` (`Frais au GA Interac/Visa`): the
/// whole description. Same result as the PDF reader, which prints ` / `
/// where the CSV has ` /` and names own accounts without their folio.
String counterparty(String description) {
  final slash = description.indexOf(' /');
  if (slash < 0) return description.trim();
  final rest = description.substring(slash + 2).trim();
  final end = rest.indexOf(' /');
  final name = (end > 0 ? rest.substring(0, end) : rest).replaceAll(RegExp(r'/$'), '').trim();
  return name.replaceAllMapped(RegExp(r'\b\d{7}-([A-Z]+\d*)$'), (m) => accountRef(m[1]!));
}

/// What comes before the first `/` with letters → `X`/`x`, digits → `9`: the
/// line type without its content, for warnings (`Xxxxxxxxx /`).
String _maskedType(String description) {
  final slash = description.indexOf('/');
  final head = slash < 0 ? description : description.substring(0, slash + 1);
  return head
      .replaceAll(RegExp(r'\p{Lu}', unicode: true), 'X')
      .replaceAll(RegExp(r'\p{Ll}', unicode: true), 'x')
      .replaceAll(RegExp(r'\d'), '9');
}

/// Account export lines by description (the CSV has no transaction codes; the
/// PDF codes they stand for in comments). First matching row wins.
const csvAccountRules = [
  // Between own accounts (VIW, VIM, VIR), account opening (OUV).
  LineRule(startsWith: 'Virement - AccesD', kind: TransactionKind.transfer, hint: 'excluded.internal_transfer'),
  LineRule(startsWith: 'Ouverture de compte', kind: TransactionKind.transfer, hint: 'excluded.internal_transfer'),
  // Bill payments (PWW): the card's own payment is a transfer.
  LineRule(
    startsWith: 'Paiement facture',
    contains: 'Mastercard',
    kind: TransactionKind.transfer,
    hint: 'excluded.card_payment',
  ),
  LineRule(
    startsWith: 'Paiement facture',
    contains: 'Odyssée',
    kind: TransactionKind.transfer,
    hint: 'excluded.card_payment',
  ),
  LineRule(startsWith: 'Paiement facture', kind: TransactionKind.expense),
  // ATM withdrawals (IRGA, RGA, RGP): the cash wallet is credited.
  LineRule(startsWith: 'Retrait', kind: TransactionKind.transfer, hint: 'excluded.cash_withdrawal'),
  LineRule(startsWith: 'Remboursement des frais', kind: TransactionKind.refund, hint: 'finance.bank_fees'),
  LineRule(startsWith: 'Frais', kind: TransactionKind.fee, hint: 'finance.bank_fees'),
  LineRule(startsWith: 'Interet', kind: TransactionKind.interest, hint: 'income.interest'),
  LineRule(startsWith: 'Paie /', direction: Direction.moneyIn, kind: TransactionKind.income, hint: 'income.salary'),
  LineRule(startsWith: 'Remboursement d', contains: 'impot', kind: TransactionKind.income, hint: 'income.tax_refund'),
  LineRule(startsWith: 'Virement manuel', kind: TransactionKind.transfer, hint: 'excluded.internal_transfer'), // VIM
  LineRule(startsWith: 'Ristourne', kind: TransactionKind.income, hint: 'income.other'), // RIS
  LineRule(startsWith: 'Boni', kind: TransactionKind.interest, hint: 'income.interest'), // BNI
  // Interac between people (VMW): "Virement Interac à / de", "Virement envoyé à".
  LineRule(startsWith: 'Annulation', contains: 'Interac', kind: TransactionKind.refund, isPerson: true),
  LineRule(
    startsWith: 'Virement envoyé',
    contains: '/Loyer',
    direction: Direction.moneyOut,
    kind: TransactionKind.expense,
    hint: 'housing.rent',
    isPerson: true,
  ),
  LineRule(
    startsWith: 'Virement envoyé',
    direction: Direction.moneyOut,
    kind: TransactionKind.expense,
    hint: 'people.sent',
    isPerson: true,
  ),
  LineRule(
    startsWith: 'Virement Interac',
    contains: '/Loyer',
    direction: Direction.moneyOut,
    kind: TransactionKind.expense,
    hint: 'housing.rent',
    isPerson: true,
  ),
  LineRule(
    startsWith: 'Virement Interac',
    direction: Direction.moneyOut,
    kind: TransactionKind.expense,
    hint: 'people.sent',
    isPerson: true,
  ),
  LineRule(startsWith: 'Virement Interac', kind: TransactionKind.income, hint: 'income.reimbursements', isPerson: true),
  // Debit card purchases (ACH).
  LineRule(startsWith: 'Achat', direction: Direction.moneyOut, kind: TransactionKind.expense),
  LineRule(startsWith: 'Achat', direction: Direction.moneyIn, kind: TransactionKind.refund),
];

/// Card export lines by description (no sections in the CSV: payments, fees
/// and interest are told apart by their first words).
const csvCardRules = [
  LineRule(
    startsWith: 'PAIEMENT',
    direction: Direction.moneyIn,
    kind: TransactionKind.transfer,
    hint: 'excluded.card_payment',
  ),
  LineRule(contains: 'BONIDOLLARS', direction: Direction.moneyIn, kind: TransactionKind.income, hint: 'income.rewards'),
  LineRule(startsWith: 'INTERETS', kind: TransactionKind.fee, hint: 'finance.interest_paid'),
  LineRule(startsWith: 'FRAIS ', kind: TransactionKind.fee, hint: 'finance.bank_fees'),
  LineRule(direction: Direction.moneyOut, kind: TransactionKind.expense),
  LineRule(direction: Direction.moneyIn, kind: TransactionKind.refund),
];

/// Reads a Desjardins CSV export (see [DesjardinsCsv]). Throws
/// [FormatException] on anything outside the known layout: a column that
/// should be empty holds a value, a line has both or no amounts, the file
/// mixes folios or cards, lines aren't in date order.
ImportedStatement readCsv(TextInput input) => switch (detectCsv(input)) {
  DesjardinsCsv.account => _readAccount(input),
  DesjardinsCsv.card => _readCard(input),
  null => throw const FormatException('Not a Desjardins CSV export'),
};

void _expectEmpty(List<String> r, Iterable<int> columns, int line) {
  for (final c in columns) {
    if (r[c - 1].trim().isNotEmpty) {
      throw FormatException('Desjardins CSV line $line: column $c holds a value (unknown layout, refused)');
    }
  }
}

/// Orders an account's lines may be in, as a function of the file's order.
/// The export (October 2026) lists days oldest first and the lines of a day
/// newest first; the running balance tells which order a file uses.
final _timeOrders = <List<T> Function<T>(List<T>, DateTime Function(T))>[
  <T>(ls, date) => _byDay(ls, date, daysReversed: false, linesReversed: true),
  <T>(ls, date) => ls,
  <T>(ls, date) => ls.reversed.toList(),
  <T>(ls, date) => _byDay(ls, date, daysReversed: true, linesReversed: true),
];

List<T> _byDay<T>(List<T> lines, DateTime Function(T) date, {required bool daysReversed, required bool linesReversed}) {
  final days = <List<T>>[];
  for (final l in lines) {
    if (days.isEmpty || date(days.last.last) != date(l)) days.add([]);
    days.last.add(l);
  }
  return [for (final d in daysReversed ? days.reversed : days) ...(linesReversed ? d.reversed : d)];
}

typedef _AccountRow = ({int line, String ref, DateTime date, String description, int amount, int balance});

/// Balance checks of [lines] in time order: the line numbers whose balance
/// isn't the previous balance plus their amount.
List<int> _balanceFailures(List<_AccountRow> lines) => [
  for (var i = 1; i < lines.length; i++)
    if (lines[i - 1].balance + lines[i].amount != lines[i].balance) i,
];

/// The account's lines in time order: the first order of [_timeOrders] whose
/// dates never go back and whose balances all hold, else the one with the
/// fewest failures (its failures refuse the import).
List<_AccountRow> _inTimeOrder(List<_AccountRow> lines) {
  List<_AccountRow>? best;
  var bestFailures = 0;
  for (final order in _timeOrders) {
    final ordered = order(lines, (r) => r.date);
    if ([for (var i = 1; i < ordered.length; i++) ordered[i].date.isBefore(ordered[i - 1].date)].contains(true)) {
      continue;
    }
    final failures = _balanceFailures(ordered).length;
    if (failures == 0) return ordered;
    if (best == null || failures < bestFailures) (best, bestFailures) = (ordered, failures);
  }
  return best ?? (throw const FormatException('Desjardins CSV: lines are not in date order'));
}

ImportedStatement _readAccount(TextInput input) {
  final rows = _rows(input, 16);
  final folios = <String>{};
  final byAccount = <String, List<_AccountRow>>{};
  for (final (i, r) in rows.indexed) {
    final line = i + 1;
    if (r.length != 16) throw FormatException('Desjardins CSV line $line: ${r.length} columns, 16 expected');
    _expectEmpty(r, [10, 11, 12, 13, 14], line);
    folios.add('${r[0]}|${r[1]}');
    final out = _cents(r, 8, line), into = _cents(r, 9, line);
    if ((out == 0) == (into == 0)) {
      throw FormatException('Desjardins CSV line $line: exactly one of withdrawal / deposit expected');
    }
    final balance = r[14].trim().isEmpty
        ? throw FormatException('Desjardins CSV line $line: balance missing')
        : _cents(r, 15, line);
    final ref = accountRef(r[2].trim());
    byAccount.putIfAbsent(ref, () => []).add((
      line: line,
      ref: ref,
      date: _parseDate(r[3], line),
      description: r[5].trim(),
      amount: into - out,
      balance: balance,
    ));
  }
  // The account refs carry no folio (same as the PDF reader): two folios
  // would merge different accounts.
  if (folios.length > 1) {
    throw FormatException('Desjardins CSV: ${folios.length} folios in one file; export one folio at a time');
  }

  final classifier = LineClassifier(csvAccountRules);
  final accounts = <ImportedAccount>[];
  final lines = <ImportedLine>[];
  final failed = <String>[];
  var checks = 0;
  for (final MapEntry(key: ref, value: rowsOfAccount) in byAccount.entries) {
    final ordered = _inTimeOrder(rowsOfAccount);
    for (var i = 1; i < ordered.length; i++) {
      checks++;
      final expected = ordered[i - 1].balance + ordered[i].amount;
      if (expected != ordered[i].balance) {
        failed.add('balance after line ${ordered[i].line} ($ref): expected ${formatCsvCents(expected)}');
      }
    }
    accounts.add(
      ImportedAccount(
        ref: ref,
        name: _accountName(ref),
        type: _accountType(ref),
        currency: 'CAD',
        closingBalance: ordered.last.balance,
      ),
    );
    for (final r in ordered) {
      final c = classifier.classify(
        description: r.description,
        amount: r.amount,
        unmatchedKey: '(no code) ${_maskedType(r.description)}',
      );
      lines.add(
        ImportedLine(
          accountRef: ref,
          date: r.date,
          amount: r.amount,
          description: r.description,
          kind: c.kind,
          categoryHint: c.hint,
          merchantText: counterparty(r.description),
          isPerson: c.isPerson,
        ),
      );
    }
  }
  final dates = lines.map((l) => l.date);
  return ImportedStatement(
    institution: 'desjardins',
    format: 'desjardins-account',
    periodStart: dates.reduce((a, b) => a.isBefore(b) ? a : b),
    periodEnd: dates.reduce((a, b) => a.isAfter(b) ? a : b),
    accounts: accounts,
    lines: lines,
    failedChecks: failed,
    checkCount: checks,
    warnings: classifier.warnings,
  );
}

ImportedStatement _readCard(TextInput input) {
  final rows = _rows(input, 13);
  final cards = <String>{};
  final parsed = <({DateTime date, String merchant, String location, int amount})>[];
  for (final (i, r) in rows.indexed) {
    final line = i + 1;
    if (r.length != 13) throw FormatException('Desjardins CSV line $line: ${r.length} columns, 13 expected');
    _expectEmpty(r, [2, 3, 7, 8, 9, 10, 11], line);
    cards.add(r[0].trim());
    final purchase = _cents(r, 12, line), credit = _cents(r, 13, line);
    if ((purchase == 0) == (credit == 0)) {
      throw FormatException('Desjardins CSV line $line: exactly one of purchase / credit expected');
    }
    // Fixed width: merchant in 25 characters, then city (13) and province.
    // Text running over the 25th character with no province at the end
    // (`CREDIT REMISE EN ARGENT BONIDOLLARS`) is one description.
    final d = r[5];
    final runsOver = d.length > 25 && d[24] != ' ' && d[25] != ' ' && !RegExp(r'\s[A-Z]{2}\s*$').hasMatch(d);
    final split = d.length > 25 && !runsOver;
    String squeeze(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');
    // A leading `*` (`*ACME.COM`) isn't printed on the PDF statement.
    final merchant = squeeze(split ? d.substring(0, 25) : d).replaceFirst(RegExp(r'^\*\s*'), '');
    final location = split ? squeeze(d.substring(25)) : '';
    parsed.add((date: _parseDate(r[3], line), merchant: merchant, location: location, amount: credit - purchase));
  }
  if (cards.length > 1) throw FormatException('Desjardins CSV: ${cards.length} cards in one file');
  final last4 = RegExp(r'(\d{4})\s*$').firstMatch(cards.single)?[1];
  if (last4 == null) throw const FormatException('Desjardins CSV: card number not found in column 1');
  final ref = 'card-$last4';

  final classifier = LineClassifier(csvCardRules);
  // No balance to tell the order of a day's lines: by date, file order kept.
  final ordered = [
    for (final (_, l)
        in (parsed.indexed.toList()
          ..sort((a, b) => a.$2.date != b.$2.date ? a.$2.date.compareTo(b.$2.date) : a.$1 - b.$1)))
      l,
  ];
  final lines = [
    for (final l in ordered)
      if (classifier.classify(description: l.merchant, amount: l.amount) case final c)
        ImportedLine(
          accountRef: ref,
          date: l.date,
          amount: l.amount,
          description: l.merchant,
          kind: c.kind,
          categoryHint: c.hint,
          merchantText: l.merchant,
          location: l.location.isEmpty ? null : l.location,
          // The export names the card used, like the card column of the PDF.
          card: last4,
        ),
  ];
  return ImportedStatement(
    institution: 'desjardins',
    format: 'desjardins-card',
    periodStart: ordered.first.date,
    periodEnd: ordered.last.date,
    accounts: [
      ImportedAccount(
        ref: ref,
        name: cards.single.replaceAll(RegExp(r'\s*\*+\s*\d{4}\s*$'), ''),
        type: AccountType.creditCard,
        currency: 'CAD',
      ),
    ],
    lines: lines,
    failedChecks: const [],
    checkCount: 0,
    warnings: classifier.warnings,
  );
}

/// `-1234.5` cents style for failed-check messages: `-12.34`.
String formatCsvCents(int cents) =>
    '${cents < 0 ? '-' : ''}${cents.abs() ~/ 100}.${(cents.abs() % 100).toString().padLeft(2, '0')}';
