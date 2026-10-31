/// Shows a statement without its content, so a coding agent running in the
/// cloud can write a parser without ever seeing personal data: letters become
/// `X` / `x`, digits `9`, layout, separators and punctuation stay. Only words
/// in [statementVocabulary] or in a reveal list the statement's owner approved
/// stay readable. Used by `banks:shape` and `banks:check`.
library;

import 'dart:io';

import 'plugin.dart';
import 'text_facts.dart';

export 'text_facts.dart' show csvFacts;

/// Words printed on statements of many banks that are never personal: column
/// headers, section titles, OFX values. Always readable in shapes. Uppercase.
const statementVocabulary = {
  // English
  'ACCOUNT', 'ACCOUNTS', 'ACTIVITY', 'AMOUNT', 'AVAILABLE', 'BALANCE', 'BANK', 'CARD', 'CHEQUE', 'CHEQUES', //
  'CHEQUING', 'CHECKING', 'CLOSING', 'CREDIT', 'CREDITS', 'CURRENCY', 'DATE', 'DEBIT', 'DEBITS', 'DEPOSIT',
  'DEPOSITS', 'DESCRIPTION', 'DETAILS', 'DUE', 'FEE', 'FEES', 'FROM', 'INTEREST', 'LIMIT', 'MINIMUM', 'NEW',
  'OPENING', 'PAGE', 'PAYMENT', 'PAYMENTS', 'PERIOD', 'POSTED', 'POSTING', 'PREVIOUS', 'PURCHASES', 'SAVINGS',
  'STATEMENT', 'SUMMARY', 'TO', 'TOTAL', 'TRANSACTION', 'TRANSACTIONS', 'TRANSFER', 'WITHDRAWAL', 'WITHDRAWALS',
  'OF', 'AND', 'THE', 'ON', 'IN', 'FOR', 'TYPE', 'NUMBER',
  // French
  'COMPTE', 'COMPTES', 'CARTE', 'CRÉDIT', 'CRÉDITS', 'DÉBIT', 'DÉBITS', 'DÉPÔT', 'DÉPÔTS', 'DEPOT', 'DEPOTS', //
  'DE', 'DU', 'DES', 'LA', 'LE', 'LES', 'AU', 'AUX', 'ET', 'EN', 'SUR', 'PAR', 'LIBELLÉ', 'LIBELLE',
  'MONTANT', 'OPÉRATION', 'OPÉRATIONS', 'OPERATION', 'OPERATIONS', 'PAIEMENT', 'PAIEMENTS', 'PÉRIODE',
  'PERIODE', 'RELEVÉ', 'RELEVE', 'RETRAIT', 'RETRAITS', 'SOLDE', 'TOTAUX', 'VALEUR', 'VIREMENT',
  'VIREMENTS', 'FRAIS', 'INTÉRÊTS', 'INTERETS', 'ACHATS', 'NOUVEAU', 'ANCIEN', 'PRÉCÉDENT', 'REPORTÉ',
  'DISPONIBLE', 'ÉCHÉANCE', 'DEVISE', 'TAUX', 'NUMÉRO',
  // OFX transaction types and values
  'INT', 'DIV', 'SRVCHG', 'DEP', 'ATM', 'POS', 'XFER', 'CHECK', 'DIRECTDEP', 'DIRECTDEBIT', 'REPEATPMT', 'OTHER',
  'CAD', 'USD', 'EUR', 'NONE', 'OFXSGML', 'USASCII', 'UTF', 'ENG', 'FRA', 'INFO', 'SUCCESS',
  // Words of the tools' own messages (warnings, failed checks)
  'UNKNOWN', 'CODE', 'LINE', 'LINES', 'COUNTED', 'AS', 'EXPENSE', 'REFUND', 'NO', 'SECTION', 'EXPECTED', 'GOT',
  'ACTUAL', 'FAIL', 'OK', 'NOT', 'FOUND', 'MISSING', 'RECOGNIZED',
};

/// Words a shape keeps readable: [statementVocabulary] plus [extra] (an
/// approved reveal list), compared uppercase.
class Reveal {
  Reveal([Iterable<String> extra = const []])
    : words = {...statementVocabulary, for (final w in extra) w.toUpperCase()};

  /// Reads a reveal list written by `banks:shape --candidates`: one word per
  /// line, `#` starts a comment.
  factory Reveal.file(String? path) => Reveal([
    if (path != null)
      for (final l in File(path).readAsLinesSync())
        if (l.split('#').first.trim() case final w when w.isNotEmpty) w,
  ]);

  final Set<String> words;

  bool keeps(String token) => token.length >= 2 && !_digit.hasMatch(token) && words.contains(token.toUpperCase());
}

final _digit = RegExp(r'\d');
final _token = RegExp(r'[\p{L}\p{N}]+', unicode: true);
final _upper = RegExp(r'\p{Lu}', unicode: true);
final _letter = RegExp(r'\p{L}', unicode: true);

/// Letter or digit runs that could be revealed: no digits, 2+ characters,
/// uppercase (`SOLDE`, `RETRAIT`).
Iterable<String> candidateTokens(String text) => _token
    .allMatches(text)
    .map((m) => m[0]!)
    .where((t) => t.length >= 2 && !_digit.hasMatch(t))
    .map((t) => t.toUpperCase());

/// [text] with every letter or digit run masked unless [reveal] keeps it:
/// uppercase letters → `X`, lowercase → `x`, digits → `9`; everything else
/// (spaces, separators, punctuation) unchanged.
String maskText(String text, Reveal reveal) => text.replaceAllMapped(_token, (m) {
  final t = m[0]!;
  if (reveal.keeps(t)) return t;
  return t.split('').map((c) {
    if (_digit.hasMatch(c)) return '9';
    if (!_letter.hasMatch(c)) return c;
    return _upper.hasMatch(c) ? 'X' : 'x';
  }).join();
});

final _ofxTag = RegExp(r'</?[A-Za-z0-9.]+>|<\?[^>]*\?>');
final _ofxHeader = RegExp(r'^[A-Z]+:[A-Za-z0-9.\-]*$');

/// One line of a text export, masked. In OFX / QFX files the tags
/// (`<STMTTRN>`, `<?xml …?>`) and the `KEY:VALUE` header lines are kept: they
/// are the format, not the content.
String maskLine(String line, String fileType, Reveal reveal) {
  if (fileType != 'ofx' && fileType != 'qfx') return maskText(line, reveal);
  if (_ofxHeader.hasMatch(line.trim())) return line;
  final out = StringBuffer();
  var at = 0;
  for (final m in _ofxTag.allMatches(line)) {
    out
      ..write(maskText(line.substring(at, m.start), reveal))
      ..write(m[0]);
    at = m.end;
  }
  return (out..write(maskText(line.substring(at), reveal))).toString();
}

/// [doc] with every word masked (coordinates unchanged).
DocumentWords maskWords(DocumentWords doc, Reveal reveal) => DocumentWords([
  for (final p in doc.pages)
    PageWords(p.width, p.height, [for (final w in p.words) Word(maskText(w.text, reveal), w.x0, w.x1, w.y)]),
]);

/// What `banks:shape` shows of one file, masked by [reveal], after a
/// `=== <heading>, …` line. PDF: rows by baseline, `y=123.4 | 54-90:XXXXX …`
/// (x0-x1:text), only page [onlyPage] when given. Text: numbered lines.
String shapeText(StatementInput input, Reveal reveal, {String heading = '', int? onlyPage}) {
  final o = StringBuffer();
  switch (input) {
    case TextInput(:final lines, :final fileType):
      o.writeln('=== $heading$fileType, ${lines.length} non-empty lines');
      csvFacts(input).forEach(o.writeln);
      for (final (i, l) in lines.indexed) {
        o.writeln('${'${i + 1}'.padLeft(4)} | ${maskLine(l, fileType, reveal)}');
      }
    case PdfInput(:final words):
      final masked = maskWords(words, reveal);
      o.writeln('=== ${heading}pdf, ${masked.pages.length} pages');
      for (final (p, page) in masked.pages.indexed) {
        if (onlyPage != null && onlyPage != p + 1) continue;
        o.writeln('--- page ${p + 1} (${page.width.round()} x ${page.height.round()} pt)');
        for (final row in groupRows(page.words)) {
          o.writeln(
            'y=${row.words.first.y.toStringAsFixed(1).padLeft(6)} | '
            '${row.words.map((w) => '${w.x0.round()}-${w.x1.round()}:${w.text}').join(' ')}',
          );
        }
      }
  }
  return o.toString();
}

/// The first [maxRows] rows of [input] masked by [reveal], words joined by
/// spaces (PDF: first page, rows by baseline): a preview for the statement's
/// owner, easier to read than [shapeText].
List<String> shapePreview(StatementInput input, Reveal reveal, {int maxRows = 60}) => switch (input) {
  TextInput(:final lines, :final fileType) => [for (final l in lines.take(maxRows)) maskLine(l, fileType, reveal)],
  PdfInput(:final words) when words.pages.isEmpty => const [],
  PdfInput(:final words) => [
    for (final row in groupRows(words.pages.first.words).take(maxRows))
      row.words.map((w) => maskText(w.text, reveal)).join(' '),
  ],
};

/// Every word of [input] that could be revealed (see [candidateTokens]).
Set<String> inputTokens(StatementInput input) => switch (input) {
  PdfInput(:final words) => {
    for (final p in words.pages)
      for (final w in p.words) ...candidateTokens(w.text),
  },
  TextInput(:final text, :final fileType) => {
    ...candidateTokens(fileType == 'ofx' || fileType == 'qfx' ? text.replaceAll(_ofxTag, ' ') : text),
  },
};

/// Candidate reveal words of several statements: those found in at least
/// [minFiles] of them and not already in [statementVocabulary], with the
/// number of files each appears in, most common first.
List<(String, int)> revealCandidates(List<StatementInput> inputs, {required int minFiles}) {
  final files = <String, int>{};
  for (final input in inputs) {
    for (final t in inputTokens(input)) {
      files.update(t, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  return [
    for (final MapEntry(key: w, value: n) in files.entries)
      if (n >= minFiles && !statementVocabulary.contains(w)) (w, n),
  ]..sort((a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
}

/// Whether [path] is inside a git working tree (a `.git` in it or a parent):
/// files listing personal words must never be written there.
bool insideGitRepository(String path) {
  var dir = File(path).absolute.parent;
  while (true) {
    if (FileSystemEntity.typeSync('${dir.path}${Platform.pathSeparator}.git') != FileSystemEntityType.notFound) {
      return true;
    }
    if (dir.parent.path == dir.path) return false;
    dir = dir.parent;
  }
}
