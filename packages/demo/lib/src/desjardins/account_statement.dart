import 'package:pdf_words/pdf_words.dart';

import '../life.dart';
import '../persona.dart';
import 'page.dart';

const _rowStep = 11.95, _lastRow = 745.0;

/// One account section as Desjardins prints it.
class _Section {
  const _Section(this.id, this.title, this.name, {this.fees = true});

  final String id;

  /// Centered title above the table (`COMPTE D'ÉPARGNE ET DE PLACEMENT`).
  final String title;

  /// Printed after the id (`Compte d'épargne`).
  final String name;

  /// The `Frais` column (not on registered accounts).
  final bool fees;
}

const _sections = [
  _Section('EOP', '', 'COMPTE AVEC OPÉRATIONS'),
  _Section('ET 1', "COMPTE D'ÉPARGNE ET DE PLACEMENT", "Compte d'épargne"),
  _Section('CS', 'CAPITAL SOCIAL', 'PART DE QUALIFICATION (P)'),
  _Section('ET 2', "COMPTE D'ÉPARGNE ET DE PLACEMENT - RÉGIME ENREGISTRÉ", 'Épargne stratégique - CELI', fees: false),
];

/// The monthly account statement ("Relevé de compte") of [month] (first day,
/// UTC): one section per account open that month, running balance on every
/// line, long descriptions wrapped, pages broken like the bank's.
DocumentWords writeAccountStatement(Life life, DateTime month) {
  final end = DateTime.utc(month.year, month.month + 1, 0);
  final balance = {...life.openings};
  for (final e in life.accountEntries) {
    if (e.date.isBefore(month)) balance[e.account] = balance[e.account]! + e.amount;
  }
  final pages = <PageBuilder>[];
  late PageBuilder page;
  var y = 0.0;
  final period = 'du 1er ${frenchMonths[month.month - 1]} au ${end.day} ${frenchMonths[month.month - 1]} ${end.year}';

  void newPage() {
    page = PageBuilder();
    pages.add(page);
    _header(page, period);
    y = 223.3;
  }

  void columns(bool fees) {
    page
      ..text('Date', 56, y)
      ..text('Code', 84, y)
      ..text('Description', 196, y);
    if (fees) page.text('Frais', 338, y);
    page
      ..text('Retrait', 388, y)
      ..text('Dépôt', 461, y)
      ..text('Solde', 534, y);
  }

  newPage();
  for (final s in _sections) {
    final entries = [
      for (final e in life.accountEntries)
        if (e.account == s.id && !e.date.isBefore(month) && !e.date.isAfter(end)) e,
    ];
    if (s.id == 'ET 2' && month.isBefore(DateTime.utc(tfsaOpened.year, tfsaOpened.month))) continue;
    if (y > 650) newPage();
    if (s.title.isNotEmpty) {
      if (y > 223.3) y += 24;
      page.right(s.title, 306 + page.width(s.title) / 2, y);
      y += 15.6;
      columns(s.fees);
      y += 19.2;
      page.text(s.id, 46, y);
      page.text(s.name, s.id.length > 2 ? 79 : 79, y);
    } else {
      page
        ..text(s.id, 46, y)
        ..text(s.name, 250, y);
      y += 15.6;
      columns(s.fees);
      y += 3.6;
    }
    y += 12;
    page
      ..text('Solde reporté', 108, y)
      ..right(money(balance[s.id]!, decimal: '.'), 578, y);
    for (final e in entries) {
      final rows = wrap(page, e.description, 205);
      if (y + _rowStep * rows.length > _lastRow) {
        newPage();
        columns(s.fees);
      }
      y += _rowStep;
      page
        ..right('${e.date.day}', 63, y)
        ..text(frenchMonthCodes[e.date.month - 1], 65, y)
        ..text(e.code, 84, y);
      for (final (i, r) in rows.indexed) {
        if (i > 0) y += _rowStep;
        page.text(r, 108, y);
      }
      balance[s.id] = balance[s.id]! + e.amount;
      page
        ..right(money(e.amount.abs(), decimal: '.'), e.amount < 0 ? 434 : 506, y)
        ..right(money(balance[s.id]!, decimal: '.'), 578, y);
    }
  }
  if (y > 700) newPage();
  y += 40;
  page
    ..text("SOMMAIRE DES FRAIS D'ADMINISTRATION", 241, y)
    ..text('Frais fixes : 3.95 \$ par mois, transactions courantes incluses.', 50, y + 15.5);
  for (final (i, p) in pages.indexed) {
    p.text('Page ${i + 1} de ${pages.length}', 513, 65);
  }
  return DocumentWords([for (final p in pages) p.build()]);
}

void _header(PageBuilder page, String period) {
  page
    ..text('CAISSE', 107, 20)
    ..text('Pour la période', 458, 25.5)
    ..text('DESJARDINS DU PLATEAU', 107, 29)
    ..text("123 RUE DE L'EXEMPLE", 107, 38)
    ..text(period, 413, 43.5)
    ..text('C.P. 1234', 107, 47)
    ..text('MONTREAL, QC', 107, 56)
    ..text('Folio', 391, 56)
    ..text('H0H 0H0 (514) 555-0100', 107, 65)
    ..text('12345', 425, 65)
    ..text('RELEVÉ DE COMPTE', 259, 98)
    ..text('Transit 815-30001-2', 197, 121.9)
    ..text(holder, 65, 142.3)
    ..text('456 AVENUE DU MODELE APP. 7', 65, 152.6)
    ..text('MONTREAL QC H0H 0H0', 65, 162.8);
}
