import 'package:pdf_words/pdf_words.dart';

import 'model.dart';
import 'text.dart';

/// Parses a Desjardins Odyssée World Elite Mastercard statement.
///
/// Layout: page 1 summary (previous balance, purchases, payments, new
/// balance), then purchases grouped per card (`Transactions effectuées avec la
/// carte de : … Carte : 5598 28** **** 3026`, each ending with a `TOTAL`),
/// then `Opérations au compte` (payments, rewards credits, fees). Line columns:
/// transaction day/month, posted day/month, description, location, Bonidollars
/// rate, amount (`CR` suffix = credit). A purchase in a foreign currency is
/// followed by a row like `79,97 DOLLAR AMERICAIN TX: 1.422158`.
CardStatement parseCardStatement(DocumentWords doc) {
  final pages = [for (final p in doc.pages) groupRows(p.words)];
  final statementDate = _statementDate(pages);
  final summary = _summary(pages.first);
  final lines = <CardLine>[];
  final totals = <String, int>{};
  CardSection? section;
  String card = '';
  double bonusColumn = 430, amountColumn = 480;

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
      } else if (t.contains('BONIDOLLARS') && t.contains('Montant') && t.first == 'Description') {
        bonusColumn = row.words.firstWhere((w) => w.text == 'BONIDOLLARS').x0;
        amountColumn = row.words.firstWhere((w) => w.text == 'Montant').x0 - 15;
      } else if (section == null) {
        continue;
      } else if (t.first == 'TOTAL' && commaAmount.hasMatch(t.last)) {
        totals[card] = (totals[card] ?? 0) + parseCents(t.last);
      } else if (t.contains('TX:') && lines.isNotEmpty) {
        lines.last.foreign = _foreign(t);
      } else if (_isLine(row) && commaAmount.hasMatch(t.last) && row.words.last.x0 >= amountColumn) {
        lines.add(_line(row, section, card, statementDate, bonusColumn));
      }
    }
  }
  final accountNumber = pages.first
      .firstWhere(
        (r) => r.texts.contains('****'),
        orElse: () => throw const FormatException('Account number not found'),
      )
      .texts
      .last;
  return CardStatement(
    statementDate: statementDate,
    accountNumber: accountNumber,
    summary: summary,
    lines: lines,
    cardTotals: totals,
  );
}

final _twoDigits = RegExp(r'^\d{2}$');

bool _isLine(Row row) =>
    row.words.length > 5 && row.words.first.x0 < 100 && row.texts.take(4).every(_twoDigits.hasMatch);

/// Location column has no header; it starts right after the description.
const _locationX = 335.0;

CardLine _line(Row row, CardSection section, String card, DateTime statementDate, double bonusColumn) {
  final t = row.texts;
  final amountText = t.last;
  final isCredit = amountText.endsWith('CR');
  final cents = parseCents(amountText);
  final middle = row.words.sublist(4, row.words.length - 1);
  final bonusIndex = middle.indexWhere((w) => w.x0 >= bonusColumn - 15 && RegExp(r'^\d+,\d{2}$').hasMatch(w.text));
  final textWords = bonusIndex < 0 ? middle : middle.sublist(0, bonusIndex);
  // Operations have no location column: their description runs across it.
  final splitX = section == CardSection.operations ? double.infinity : _locationX;
  return CardLine(
    card: card,
    section: section,
    transactionDate: inferDate(int.parse(t[0]), int.parse(t[1]), statementDate),
    postedDate: inferDate(int.parse(t[2]), int.parse(t[3]), statementDate),
    description: textWords.where((w) => w.x0 < splitX).map((w) => w.text).join(' '),
    location: textWords.where((w) => w.x0 >= splitX).map((w) => w.text).join(' '),
    amount: isCredit ? cents : -cents,
    isCredit: isCredit,
    bonusRate: bonusIndex < 0 ? null : parseCents(middle[bonusIndex].text),
  );
}

const _currencies = {
  'DOLLAR AMERICAIN': 'USD',
  'EURO': 'EUR',
  'LIVRE STERLING': 'GBP',
  'FRANC SUISSE': 'CHF',
  'YEN': 'JPY',
  'DOLLAR AUSTRALIEN': 'AUD',
  'PESO MEXICAIN': 'MXN',
};

ForeignAmount _foreign(List<String> t) {
  final tx = t.indexOf('TX:');
  final name = t.sublist(1, tx).join(' ');
  return ForeignAmount(parseCents(t[0]), _currencies[name] ?? name, tx + 1 < t.length ? t[tx + 1] : '');
}

DateTime _statementDate(List<List<Row>> pages) {
  for (final row in pages.first) {
    final t = row.texts;
    final j = t.indexOf('Jour');
    if (t.take(3).join(' ') == 'DATE DU RELEVÉ' && j >= 0 && t.length > j + 5) {
      return DateTime.utc(int.parse(t[j + 5]), int.parse(t[j + 3]), int.parse(t[j + 1]));
    }
  }
  throw const FormatException('Statement date ("DATE DU RELEVÉ Jour … Mois … Année …") not found');
}

const _summaryLabels = {
  'Solde précédent': 'previousBalance',
  'Achats /': 'purchases',
  "Avances d'argent": 'cashAdvances',
  'Frais de': 'creditFees',
  'Mensualité financement': 'installment',
  'Paiements /': 'payments',
  'Nouveau solde': 'newBalance',
};

/// Summary amounts sit in a column between x 200 and 290 on the first page.
Map<String, int> _summary(List<Row> firstPage) {
  final out = <String, int>{};
  for (final row in firstPage) {
    if (row.texts.length < 2 || row.words.first.x0 > 100) continue;
    final key = _summaryLabels[row.texts.take(2).join(' ')];
    if (key == null || out.containsKey(key)) continue;
    final amount = row.between(200, 290).where((w) => commaAmount.hasMatch(w.text)).firstOrNull;
    if (amount != null) out[key] = parseCents(amount.text);
  }
  return out;
}
