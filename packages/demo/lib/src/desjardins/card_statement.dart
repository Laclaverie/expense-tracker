import 'package:pdf_words/pdf_words.dart';

import '../life.dart';
import '../persona.dart';
import 'page.dart';

/// Desjardins changed the card statement on this date (new card system).
final DateTime newCardLayoutFrom = DateTime.utc(2026, 10, 1);

/// The card statement closing on [closing] (one of [Life.cardStatementDates]),
/// in the layout Desjardins used then.
DocumentWords writeCardStatement(Life life, DateTime closing) {
  final i = life.cardStatementDates.indexOf(closing);
  if (i < 0) throw ArgumentError('$closing is not a statement date');
  final from = i == 0 ? DateTime.utc(1900) : life.cardStatementDates[i - 1];
  bool inPeriod(CardEntry e) => e.posted.isAfter(from) && !e.posted.isAfter(closing);
  final previous = -life.cardEntries.where((e) => !e.posted.isAfter(from)).fold(0, (s, e) => s + e.amount);
  final period = life.cardEntries.where(inPeriod).toList();
  final s = _Statement(life.persona, closing, previous, period);
  return closing.isBefore(newCardLayoutFrom) ? _original(s) : _layout2026(s);
}

class _Statement {
  _Statement(this.persona, this.closing, this.previous, this.entries);

  final Persona persona;

  final DateTime closing;

  /// Owed at the previous statement (positive).
  final int previous;
  final List<CardEntry> entries;

  List<CardEntry> purchases(String card) => [
    for (final e in entries)
      if (!e.operation && e.card == card) e,
  ];
  List<CardEntry> get operations => [
    for (final e in entries)
      if (e.operation) e,
  ];
  Iterable<String> get cards => [persona.holderCard, ?persona.partnerCard].where((c) => purchases(c).isNotEmpty);

  int get debits => -entries.where((e) => e.amount < 0).fold(0, (s, e) => s + e.amount);
  int get payments =>
      entries.where((e) => e.amount > 0 && e.merchant.startsWith('PAIEMENT')).fold(0, (s, e) => s + e.amount);
  int get otherCredits =>
      entries.where((e) => e.amount > 0 && !e.merchant.startsWith('PAIEMENT')).fold(0, (s, e) => s + e.amount);
  int get newBalance => previous + debits - payments - otherCredits;
  int get minimum => newBalance <= 0 ? 0 : (newBalance * .05).round().clamp(1000, newBalance);
  DateTime get due => DateTime.utc(closing.year, closing.month, closing.day + 21);
  String cardHolder(String card) => card == persona.partnerCard ? persona.partner! : persona.holder;
}

String _total(List<CardEntry> lines) => money(-lines.fold(0, (s, e) => s + e.amount));

// ------------------------------------------------------------------ original

const _step = 7.2, _bottom = 760.0;

DocumentWords _original(_Statement s) {
  final pages = <PageBuilder>[];
  late PageBuilder page;
  var y = 0.0;

  void newPage() {
    page = PageBuilder(size: 7);
    pages.add(page);
    _originalHeader(page, s);
    y = 289.0;
  }

  void columns() {
    page
      ..text('Date de transaction', 77, y + 13.7)
      ..text("Date d'inscription", 151, y + 13.7)
      ..text('Description', 302, y + 18.5)
      ..text('BONIDOLLARS', 429, y + 18.5)
      ..text('Montant', 495, y + 18.5)
      ..text('J M J M', 97, y + 23.2);
    y += 35.1 - _step;
  }

  void line(CardEntry e) {
    if (y + _step * 2 > _bottom) {
      newPage();
      columns();
    }
    y += _step;
    page
      ..right(two(e.date.day), 101, y)
      ..right(two(e.date.month), 125, y)
      ..right(two(e.posted.day), 173, y)
      ..right(two(e.posted.month), 197, y);
    if (e.operation) {
      page.text(e.merchant, 225, y);
    } else {
      page.text(e.merchant, 221, y);
      final parts = e.location.split(' ');
      final region = parts.length > 1 && RegExp(r'^[A-Z]{2}$').hasMatch(parts.last) ? parts.removeLast() : null;
      page.text(parts.join(' '), 341, y);
      if (region != null) page.text(region, 403, y);
      if (e.bonusRate != null) {
        page
          ..right(money(e.bonusRate!), 460, y)
          ..text('%', 465, y);
      }
    }
    page.right(money(e.amount, credit: e.amount > 0), e.amount > 0 ? 542 : 532, y);
    if (e.foreign case final f?) {
      y += _step;
      page.text('${money(f.cents)} DOLLAR AMERICAIN TX: ${f.rate.toStringAsFixed(6)}', 230, y);
    }
  }

  newPage();
  // Page 1: summary, then the first lines.
  _originalSummary(page, s);
  y = 633.5;
  page.text('DESCRIPTION DES TRANSACTIONS COURANTES', 91, y);
  y = 653.9;
  for (final card in s.cards) {
    if (y + 60 > _bottom) newPage();
    page
      ..text('Transactions effectuées avec la carte de : ${s.cardHolder(card)}', 77, y)
      ..text('Carte : 5555 55** **** $card', 432, y);
    columns();
    final lines = s.purchases(card);
    lines.forEach(line);
    y += 16;
    page
      ..text('TOTAL', 400, y)
      ..right(_total(lines), 532, y);
    y += 20;
  }
  if (s.operations.isNotEmpty) {
    if (y + 60 > _bottom) newPage();
    page
      ..text('Opérations au compte', 77, y)
      ..text('5555 55** **** ${s.persona.cardAccount}', 211, y);
    columns();
    s.operations.forEach(line);
    y += 20;
  }
  if (y + 120 > _bottom) newPage();
  y += 30;
  page
    ..text('BONIDOLLARS ACCUMULÉS DEPUIS LE DERNIER RELEVÉ', 91, y)
    ..text('Épicerie 3,00 % · Restaurants 3,00 % · Transport 2,00 % · Autres achats 1,00 %', 72, y + 15.5);
  for (final (i, p) in pages.indexed) {
    p.text('Page : ${i + 1} de ${pages.length}', 489, 265.6);
  }
  return DocumentWords([for (final p in pages) p.build()]);
}

void _originalHeader(PageBuilder page, _Statement s) {
  final d = s.closing;
  page
    ..text('Relevé de compte', 457, 22)
    ..text('Numéro de compte', 419, 61.6)
    ..text('5555 55** **** ${s.persona.cardAccount}', 382, 75.3)
    ..text('Date du', 82, 88.6)
    ..text('Jour Mois Année', 117, 88.6)
    ..text('relevé', 82, 97.6)
    ..text('${two(d.day)} ${two(d.month)} ${d.year}', 119, 102.3)
    ..text(s.persona.holder, 72, 157.4)
    ..text('456 AVENUE DU MODELE APP. 7', 72, 166.4)
    ..text('MONTREAL QC H0H 0H0', 72, 175.4)
    ..text('DATE DU RELEVÉ Jour ${two(d.day)} Mois ${two(d.month)} Année ${d.year}', 72, 256.6)
    ..text('DESJARDINS ODYSSEE WORLDELITE MASTERCARD', 309, 256.6);
}

void _originalSummary(PageBuilder page, _Statement s) {
  void row(double y, String label, String sign, int cents) {
    page.text(label, 77, y);
    if (sign.isNotEmpty) page.text(sign, 225, y);
    page.right(money(cents), 269, y);
  }

  page.text('SOMMAIRE DES TRANSACTIONS COURANTES', 91, 358);
  row(378.3, 'Solde précédent', '', s.previous);
  row(396.3, 'Achats / débits', '+', s.debits);
  row(414.3, "Avances d'argent", '+', 0);
  row(432.3, 'Frais de crédit', '+', 0);
  row(450.3, 'Mensualité financement', '+', 0);
  row(468.3, 'Paiements / crédits', '-', s.payments + s.otherCredits);
  row(486.3, 'Nouveau solde actuel', '=', s.newBalance);
  final due = s.due;
  page
    ..text("Date d'échéance : Jour ${two(due.day)} Mois ${two(due.month)} Année ${due.year}", 365, 468.3)
    ..text('Paiement minimum', 375, 486.3)
    ..right(money(s.minimum), 441, 494);
}

// -------------------------------------------------------------- 2026 layout

const _step26 = 11.3, _bottom26 = 752.0;

DocumentWords _layout2026(_Statement s) {
  final pages = <PageBuilder>[];
  late PageBuilder page;
  var y = 0.0;
  final d = s.closing;
  final dateRow = 'Date du relevé Jour ${two(d.day)} Mois ${two(d.month)} Année ${d.year}';

  void newPage({String title = 'DESCRIPTION DES TRANSACTIONS COURANTES (suite)'}) {
    page = PageBuilder(size: 8.5);
    pages.add(page);
    page
      ..text(dateRow, 36, 42.5)
      ..text('Odyssée World Elite Mastercard', 436, 42.5)
      ..text(title, 36, 62.6);
    y = 62.6;
  }

  void columns() {
    y += 18;
    page
      ..text('Date de transaction', 40, y)
      ..text("Date d'inscription", 115, y)
      ..text('Description', 305, y)
      ..text('Montant', 508, y);
    y += 3.6;
  }

  String date(DateTime d) => '${d.year}/${two(d.month)}/${two(d.day)}';

  void line(CardEntry e) {
    if (y + _step26 * 3 > _bottom26) {
      newPage();
      columns();
    }
    y += _step26;
    page
      ..text(date(e.date), 53, y)
      ..text(date(e.posted), 125, y);
    final end = page.text(e.merchant, 184, y);
    if (!e.operation && e.location.isNotEmpty) {
      // A location without a region code is set apart by the name's padding.
      final region = RegExp(r' [A-Z]{2}$').hasMatch(e.location);
      page.text(e.location, region ? end + page.space : end + 13, y);
    }
    page.right(money(e.amount, credit: e.amount > 0), e.amount > 0 ? 573 : 562, y);
    if (e.foreign case final f?) {
      y += _step26;
      page.text(f.currency, 184, y);
      y += _step26;
      page.text('${(f.cents / 100).toStringAsFixed(2)} X ${f.rate.toStringAsFixed(8)}', 184, y);
    }
  }

  // Page 1: summary only.
  page = PageBuilder(size: 8.5);
  pages.add(page);
  _summary2026(page, s, dateRow);
  newPage(title: 'DESCRIPTION DES TRANSACTIONS COURANTES');
  for (final card in s.cards) {
    if (y + 60 > _bottom26) newPage();
    y += 17;
    page
      ..text('Transactions effectuées avec la carte de : ${s.cardHolder(card)}', 40, y)
      ..text('XXXX XXXX XXXX $card', 497, y);
    columns();
    final lines = s.purchases(card);
    lines.forEach(line);
    y += 14.4;
    page
      ..text('Total :', 435, y)
      ..right(_total(lines), 561, y);
    y += 20;
  }
  if (s.operations.isNotEmpty) {
    if (y + 60 > _bottom26) newPage();
    y += 17;
    page.text('DESCRIPTION DES OPÉRATIONS AU COMPTE', 36, y);
    y += 17;
    page
      ..text('Opérations au compte', 40, y)
      ..text('XXXX XXXX XXXX ${s.persona.cardAccount}', 497, y);
    columns();
    s.operations.forEach(line);
  }
  newPage(title: 'BONIDOLLARS ACCUMULÉS DEPUIS LE DERNIER RELEVÉ');
  for (final (i, p) in pages.indexed) {
    p.text('Page ${i + 1} de ${pages.length}', 543, 779.5);
  }
  return DocumentWords([for (final p in pages) p.build()]);
}

void _summary2026(PageBuilder page, _Statement s, String dateRow) {
  final due = s.due;
  void row(double y, String label, String sign, int? cents) {
    page.text(label, 40, y);
    if (sign.isNotEmpty) page.text(sign, 254, y);
    if (cents != null) page.right(money(cents), 335, y);
  }

  page
    ..text('Relevé de compte', 499, 26.6)
    ..text('Numéro de compte', 447, 47.5)
    ..text('XXXX XXXX XXXX ${s.persona.cardAccount}', 413, 64.1)
    ..text('Odyssée World Elite Mastercard', 36, 71.8)
    ..text('Date du Jour Mois Année', 40, 83.5)
    ..text("Date d'échéance Jour ${two(due.day)} Mois ${two(due.month)} Année ${due.year}", 191, 83.5)
    ..text(s.persona.holder, 72, 157.2)
    ..text('456 AVENUE DU MODELE APP. 7', 72, 168.5)
    ..text('MONTREAL QC H0H 0H0', 72, 179.8)
    ..text(dateRow, 36, 276.5)
    ..text('Odyssée World Elite Mastercard', 436, 276.5)
    ..text('SOMMAIRE DU COMPTE', 40, 354.2);
  row(370.3, 'SOLDE TOTAL PRÉCÉDENT', '', s.previous);
  row(384.2, 'PAIEMENTS', '-', s.payments);
  row(398.6, 'CRÉDITS', '-', s.otherCredits);
  row(413.0, 'ACHATS / DÉBITS', '+', s.debits);
  row(427.4, "AVANCES D'ARGENT", '+', 0);
  row(441.8, 'FRAIS DE CRÉDIT', '+', 0);
  row(455.5, 'NOUVEAU SOLDE TOTAL', '', null);
  row(464.6, 'Inclut le solde actuel et des achats', '=', s.newBalance);
  row(568.1, 'PAIEMENT MINIMUM DÛ', '=', s.minimum);
}
