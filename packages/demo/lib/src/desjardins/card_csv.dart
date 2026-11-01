import '../life.dart';

/// The card lines bought after the statement before [closing] (one of
/// [Life.cardStatementDates]) up to it, as AccèsD card exports ("Télécharger
/// les transactions" for that date range). By purchase date, not posting
/// date: a purchase made on the previous closing day but posted after it is
/// on no file (the statements list by posting date, the export by purchase
/// date). One file per card, as the bank gives them, named
/// `releve-carte-<last 4>.csv`. Layout: `banks/lib/src/desjardins/csv/reader.dart`
/// (13 columns, no header, empty columns `""`, merchant in 25 characters then
/// city in 13 and province, oldest day first). Payments and fees go with the
/// holder's card.
Map<String, String> writeCardCsvs(Life life, DateTime closing) {
  final i = life.cardStatementDates.indexOf(closing);
  if (i < 1) throw ArgumentError('$closing is not a statement date after the first');
  final from = life.cardStatementDates[i - 1];
  final p = life.persona;
  final byCard = <String, List<CardEntry>>{};
  for (final e in life.cardEntries) {
    if (!e.date.isAfter(from) || e.date.isAfter(closing)) continue;
    byCard.putIfAbsent(e.operation ? p.holderCard : e.card, () => []).add(e);
  }
  return {
    for (final MapEntry(key: card, value: entries) in byCard.entries)
      'releve-carte-$card.csv': _file('ODYSSEE WORLD ELITE **** $card', entries),
  };
}

String _file(String card, List<CardEntry> entries) {
  final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
  final out = StringBuffer();
  for (final (n, e) in sorted.indexed) {
    final description = e.operation || e.location.isEmpty ? e.merchant : _place(e);
    final cents = _amount(e.amount.abs());
    out.writeln(
      [
        card,
        '""',
        '""',
        _date(e.date),
        '${n + 1}',
        description,
        for (var c = 7; c <= 11; c++) '""',
        if (e.amount < 0) ...[cents, '""'] else ...['""', cents],
      ].join(','),
    );
  }
  return out.toString();
}

/// Merchant in 25 characters, city in 13, then the province.
String _place(CardEntry e) {
  final space = e.location.lastIndexOf(' ');
  final hasRegion = space > 0 && RegExp(r'^[A-Z]{2}$').hasMatch(e.location.substring(space + 1));
  final city = hasRegion ? e.location.substring(0, space) : e.location;
  final region = hasRegion ? e.location.substring(space + 1) : '';
  return '${e.merchant.padRight(25)}${city.padRight(13)}$region'.trimRight();
}

String _date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

String _amount(int cents) => '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
