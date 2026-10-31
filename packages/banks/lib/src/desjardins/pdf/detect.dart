import 'package:pdf_words/pdf_words.dart';

import 'account_parser.dart';
import 'card_parser.dart';
import 'card_parser_2026.dart';
import 'model.dart';

enum DesjardinsFormat { account, card }

/// One printed layout of a statement: recognized from the first page's text.
typedef Layout<T extends Statement> = ({
  String name,
  bool Function(String firstPage) matches,
  T Function(DocumentWords doc) parse,
});

/// Card statement layouts, newest first. Desjardins changes them (new card
/// system in October 2026); every layout gives the same [CardStatement], so
/// the format id, account and merchants stay the same across layouts.
final List<Layout<CardStatement>> cardLayouts = [
  (name: '2026-10', matches: isCardStatement2026, parse: parseCardStatement2026),
  (name: 'original', matches: (t) => t.contains('ODYSSEE WORLDELITE MASTERCARD'), parse: parseCardStatement),
];

/// First page text row by row: the PDF's own word order can mix rows.
String _firstPage(DocumentWords doc) => groupRows(doc.pages.first.words).map((r) => r.texts.join(' ')).join('\n');

Layout<CardStatement>? cardLayout(DocumentWords doc) {
  if (doc.pages.isEmpty) return null;
  final text = _firstPage(doc);
  return cardLayouts.where((l) => l.matches(text)).firstOrNull;
}

/// Recognizes a Desjardins statement from its first page, or returns null.
DesjardinsFormat? detectFormat(DocumentWords doc) {
  if (doc.pages.isEmpty) return null;
  if (cardLayout(doc) != null) return DesjardinsFormat.card;
  final text = _firstPage(doc);
  if (text.contains('RELEVÉ DE COMPTE') && text.contains('DESJARDINS')) return DesjardinsFormat.account;
  return null;
}

/// Detects the format and parses. Throws [FormatException] for unknown documents.
Statement parseStatement(DocumentWords doc) => switch (detectFormat(doc)) {
  DesjardinsFormat.account => parseAccountStatement(doc),
  DesjardinsFormat.card => cardLayout(doc)!.parse(doc),
  null => throw const FormatException('Not a recognized Desjardins statement'),
};
