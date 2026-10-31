import 'package:banks/plugin.dart';

import 'model.dart';
import 'text.dart';

/// Recognizes the card statement layout introduced in October 2026 (new card
/// system): mixed-case `Odyssée World Elite Mastercard` header and the card
/// summary headings. The card name alone is not enough: account statements
/// print it on the card payment line.
bool isCardStatement2026(String firstPage) =>
    firstPage.contains('Odyssée World Elite Mastercard') &&
    firstPage.contains('SOMMAIRE DU COMPTE') &&
    firstPage.contains('PAIEMENT MINIMUM DÛ');

/// Parses a Desjardins Odyssée World Elite Mastercard statement, October 2026
/// layout.
///
/// Differences from the original layout (`card_parser.dart`): full dates
/// `2026/09/19`, no location column (merchant, city and province in one run of
/// words), no Bonidollars rate per line (the column is read if it comes back),
/// a foreign amount takes two rows under the line (`USD`, then
/// `5.40 X 1.46111111`), each card ends with `Total :`, and the summary lists
/// payments and credits separately.
CardStatement parseCardStatement2026(DocumentWords doc) {
  final pages = [for (final p in doc.pages) groupRows(p.words)];
  final statementDate = _statementDate(pages.first);
  final lines = <CardLine>[];
  final totals = <String, int>{};
  CardSection? section;
  String card = '';
  double amountColumn = 480;
  double? bonusColumn;
  String? foreignCurrency;

  for (final rows in pages) {
    for (final row in rows) {
      final t = row.texts;
      if (t.length > 2 && t[0] == 'Transactions' && t[1].startsWith('effectu')) {
        section = CardSection.purchases;
        card = t.last;
      } else if (t.length > 2 && t[0] == 'Opérations' && t[1] == 'au') {
        section = CardSection.operations;
        card = t.last;
      } else if (t.first == 'BONIDOLLARS' && t.length > 1 && t[1].startsWith('ACCUMUL')) {
        section = null;
      } else if (t.first == 'Date' && t.contains('Description') && t.contains('Montant')) {
        amountColumn = row.words.firstWhere((w) => w.text == 'Montant').x0 - 20;
        bonusColumn = row.words.where((w) => w.text == 'BONIDOLLARS').firstOrNull?.x0;
      } else if (section == null) {
        continue;
      } else if (t.first == 'Total' && t.length > 1 && t[1] == ':' && commaAmount.hasMatch(t.last)) {
        totals[card] = (totals[card] ?? 0) + parseCents(t.last);
      } else if (t.length == 1 && RegExp(r'^[A-Z]{3}$').hasMatch(t.first) && lines.isNotEmpty) {
        foreignCurrency = t.first;
      } else if (foreignCurrency != null && t.length == 3 && t[1] == 'X') {
        lines.last.foreign = ForeignAmount(parseCents(t[0]), foreignCurrency, t[2]);
        foreignCurrency = null;
      } else if (_isLine(row) && commaAmount.hasMatch(t.last) && row.words.last.x0 >= amountColumn) {
        lines.add(_line(row, section, card, bonusColumn));
        foreignCurrency = null;
      }
    }
  }
  final accountNumber = pages.first
      .firstWhere(
        (r) => r.texts.contains('XXXX'),
        orElse: () => throw const FormatException('Account number not found'),
      )
      .texts
      .last;
  return CardStatement(
    statementDate: statementDate,
    accountNumber: accountNumber,
    summary: _summary(pages.first),
    lines: lines,
    cardTotals: totals,
  );
}

final _fullDate = RegExp(r'^(\d{4})/(\d{2})/(\d{2})$');

bool _isLine(Row row) =>
    row.words.length > 3 &&
    row.words.first.x0 < 100 &&
    _fullDate.hasMatch(row.texts[0]) &&
    _fullDate.hasMatch(row.texts[1]);

DateTime _date(String text) {
  final m = _fullDate.firstMatch(text)!;
  return DateTime.utc(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}

CardLine _line(Row row, CardSection section, String card, double? bonusColumn) {
  final t = row.texts;
  final amountText = t.last;
  final isCredit = amountText.endsWith('CR');
  final cents = parseCents(amountText);
  final middle = row.words.sublist(2, row.words.length - 1);
  final bonusIndex = bonusColumn == null
      ? -1
      : middle.indexWhere((w) => w.x0 >= bonusColumn - 15 && RegExp(r'^\d+,\d{2}$').hasMatch(w.text));
  final textWords = bonusIndex < 0 ? middle : middle.sublist(0, bonusIndex);
  // Operations have no location: the whole text is the description.
  final (description, location) = section == CardSection.operations
      ? (textWords.map((w) => w.text).join(' '), '')
      : splitMerchant(textWords);
  return CardLine(
    card: card,
    section: section,
    transactionDate: _date(t[0]),
    postedDate: _date(t[1]),
    // `*INTERNET ARCHIVE`: the original layout had no leading `*`, keep merchants the same.
    description: description.startsWith('*') ? description.substring(1) : description,
    location: location,
    amount: isCredit ? cents : -cents,
    isCredit: isCredit,
    bonusRate: bonusIndex < 0 ? null : parseCents(middle[bonusIndex].text),
  );
}

/// The card network's merchant name is cut at 22 characters, the city at 13.
const _nameWidth = 22, _cityWidth = 13;

/// Splits `ACME WHOLESALE W123 LAVAL QC` into the merchant name
/// (`ACME WHOLESALE W123`) and the location (`LAVAL QC`), as the
/// original layout printed them in two columns, so merchants stay the same.
///
/// The last word is a 2-letter province, state or country code. The city is
/// what follows a name cut at its full 22 characters; otherwise one word, or two
/// after a prefix like `SAINT`. Without a region code, a wide gap (the name
/// padded to its width) separates the location (`Patreon* Membership  Internet`).
(String, String) splitMerchant(List<Word> words) {
  String join(Iterable<Word> ws) => ws.map((w) => w.text).join(' ');
  if (words.length < 2) return (join(words), '');
  final hasRegion = RegExp(r'^[A-Z]{2}$').hasMatch(words.last.text);
  if (!hasRegion) {
    for (var i = words.length - 1; i > 0; i--) {
      if (words[i].x0 - words[i - 1].x1 > 8) return (join(words.take(i)), join(words.skip(i)));
    }
    return (join(words), '');
  }
  final before = words.sublist(0, words.length - 1);
  if (before.length < 2) return ('', join(words));
  bool fits(int i) => join(before.skip(i)).length <= _cityWidth;
  bool isPrefix(int i) => cityPrefixes.contains(before[i].text.toUpperCase());
  var split = -1;
  for (var i = 1; i < before.length; i++) {
    if (join(before.take(i)).length == _nameWidth && fits(i)) split = i;
  }
  if (split > 1 && isPrefix(split - 1) && fits(split - 1)) {
    split--; // `PHARMAPRIX #1957 SAINT LEONARD`: 22 characters by chance
  } else if (split < 0) {
    split = before.length - 1;
    final twoWords = split > 1 && (isPrefix(split - 1) || citySuffixes.contains(before[split].text.toUpperCase()));
    if (twoWords && fits(split - 1)) split--;
  }
  return (join(before.take(split)), join(words.skip(split)));
}

/// `Date du relevé Jour 20 Mois 10 Année 2026`.
DateTime _statementDate(List<Row> firstPage) {
  for (final row in firstPage) {
    final t = row.texts;
    final j = t.indexOf('Jour');
    if (t.take(3).join(' ') == 'Date du relevé' && j >= 0 && t.length > j + 5 && t[j + 2] == 'Mois') {
      return DateTime.utc(int.parse(t[j + 5]), int.parse(t[j + 3]), int.parse(t[j + 1]));
    }
  }
  throw const FormatException('Statement date ("Date du relevé Jour … Mois … Année …") not found');
}

/// Summary labels -> keys of [CardStatement.summary]. Payments and credits are
/// printed apart; their sum is the old `Paiements / crédits`.
const _summaryLabels = {
  'SOLDE TOTAL PRÉCÉDENT': 'previousBalance',
  'PAIEMENTS': 'payments',
  'CRÉDITS': 'payments',
  'ACHATS / DÉBITS': 'purchases',
  "AVANCES D'ARGENT": 'cashAdvances',
  'FRAIS DE CRÉDIT': 'creditFees',
  'NOUVEAU SOLDE TOTAL': 'newBalance',
};

/// Summary amounts sit in a column between x 260 and 380 on the first page.
/// `NOUVEAU SOLDE TOTAL` has its amount on the next row.
Map<String, int> _summary(List<Row> firstPage) {
  final out = <String, int>{};
  final seen = <String>{};
  String? pending;
  for (final row in firstPage) {
    final amount = row.between(260, 380).where((w) => commaAmount.hasMatch(w.text)).firstOrNull;
    if (pending != null && amount != null) {
      out[pending] = parseCents(amount.text);
      pending = null;
      continue;
    }
    if (row.words.first.x0 > 100) continue;
    final label = row.words.takeWhile((w) => w.x0 < 250).map((w) => w.text).join(' ');
    final key = _summaryLabels[label];
    if (key == null || !seen.add(label)) continue;
    if (amount == null) {
      pending = key;
    } else {
      out[key] = (out[key] ?? 0) + parseCents(amount.text);
    }
  }
  return out;
}
