/// `banks:compare`: the same accounts read from two sources (monthly PDF
/// statements and a CSV export) side by side, to measure one reader against
/// the other. Lines are matched by account, amount and date over the days
/// both sources cover; the report holds counts, months, kinds and masked line
/// types only, no amount, name or description (docs/10-adding-a-bank.md §0b).
library;

import 'package:core/core.dart' show normalizeMerchant;

import 'plugin.dart';
import 'shape.dart';

/// One file read by a plug-in.
class Source {
  Source(this.fileType, this.statement);
  final String fileType;
  final ImportedStatement statement;
}

/// How a CSV line was paired with a PDF line.
enum Pairing { sameDate, postedDate, nearDate }

class _Pair {
  _Pair(this.pdf, this.csv, this.how);
  final ImportedLine pdf, csv;
  final Pairing how;
}

String _day(DateTime d) => d.toIso8601String().substring(0, 10);
String _month(DateTime d) => d.toIso8601String().substring(0, 7);

/// Days of [s] read from its lines too: a card statement's start is an estimate.
(DateTime, DateTime) _span(ImportedStatement s, String ref) {
  var start = s.periodStart;
  for (final l in s.lines) {
    if (l.accountRef == ref && l.date.isBefore(start)) start = l.date;
  }
  return (start, s.periodEnd);
}

bool _inAny(DateTime d, List<(DateTime, DateTime)> spans) => spans.any((s) => !d.isBefore(s.$1) && !d.isAfter(s.$2));

/// The part of a description naming the line type (before the first `/`),
/// masked except for statement words and [reveal].
String _type(String description, Reveal reveal) {
  final slash = description.indexOf('/');
  return maskText(slash < 0 ? description : description.substring(0, slash + 1), reveal).trim();
}

/// The report: one block per account found in both a PDF and a text source,
/// then accounts found in one source only.
List<String> compareSources(List<Source> sources, Reveal reveal) {
  // The same statement saved twice (two folders, "releve (1).pdf"): the app
  // refuses the copy, so it counts once here too.
  final seen = <(String, String, DateTime)>{};
  final pdf = <ImportedStatement>[];
  var copies = 0;
  for (final s in sources.where((s) => s.fileType == 'pdf').map((s) => s.statement)) {
    if (seen.add((s.institution, s.format, s.periodEnd))) {
      pdf.add(s);
    } else {
      copies++;
    }
  }
  if (pdf.isEmpty || !sources.any((s) => s.fileType != 'pdf')) {
    return ['need PDF statements and at least one export (CSV…) to compare'];
  }
  final pdfRefs = {
    for (final s in pdf)
      for (final a in s.accounts) (s.institution, a.ref),
  };
  // A card export may name the card used where the statements name the card
  // account: lines of the PDFs tell which account each card belongs to.
  final cardAccounts = <(String, String), Set<String>>{};
  for (final s in pdf) {
    for (final l in s.lines) {
      if (l.card != null) cardAccounts.putIfAbsent((s.institution, 'card-${l.card}'), () => {}).add(l.accountRef);
    }
  }
  final out = <String>[if (copies > 0) '$copies PDF(s) skipped: same statement as another PDF'];
  final text = [
    for (final s in sources.where((s) => s.fileType != 'pdf').map((s) => s.statement))
      _renamed(
        s,
        {
          for (final a in s.accounts)
            if (!pdfRefs.contains((s.institution, a.ref)) && cardAccounts[(s.institution, a.ref)]?.length == 1)
              a.ref: cardAccounts[(s.institution, a.ref)]!.single,
        },
        out,
        reveal,
      ),
  ];
  final refs = <(String, String)>{
    for (final s in [...pdf, ...text])
      for (final a in s.accounts) (s.institution, a.ref),
  };
  final onlyOne = <String>[];
  for (final (institution, ref) in refs) {
    bool has(ImportedStatement s) => s.institution == institution && s.accounts.any((a) => a.ref == ref);
    final p = pdf.where(has).toList(), t = text.where(has).toList();
    final name = '$institution ${maskText(ref, reveal)}';
    if (p.isEmpty || t.isEmpty) {
      onlyOne.add('$name: only in ${p.isEmpty ? 'the export' : 'the PDFs'}');
      continue;
    }
    out.addAll(_compareAccount(name, ref, p, t, reveal));
  }
  if (onlyOne.isNotEmpty) {
    out.add('accounts in one source only (different refs? the export may name them differently):');
    out.addAll([for (final o in onlyOne) '  $o']);
  }
  return out;
}

/// [s] with the accounts of [refs] renamed (export card ref -> PDF account).
ImportedStatement _renamed(ImportedStatement s, Map<String, String> refs, List<String> out, Reveal reveal) {
  if (refs.isEmpty) return s;
  for (final MapEntry(:key, :value) in refs.entries) {
    out.add(
      'export ${maskText(key, reveal)} is a card used on the PDF account ${maskText(value, reveal)}: compared as one',
    );
  }
  return ImportedStatement(
    institution: s.institution,
    format: s.format,
    periodStart: s.periodStart,
    periodEnd: s.periodEnd,
    coversSincePrevious: s.coversSincePrevious,
    accounts: [
      for (final a in s.accounts)
        ImportedAccount(
          ref: refs[a.ref] ?? a.ref,
          name: a.name,
          type: a.type,
          currency: a.currency,
          closingBalance: a.closingBalance,
        ),
    ],
    lines: [
      for (final l in s.lines)
        ImportedLine(
          accountRef: refs[l.accountRef] ?? l.accountRef,
          date: l.date,
          postedDate: l.postedDate,
          amount: l.amount,
          description: l.description,
          code: l.code,
          kind: l.kind,
          merchantText: l.merchantText,
          location: l.location,
          bonusRate: l.bonusRate,
          foreignCents: l.foreignCents,
          foreignCurrency: l.foreignCurrency,
          fxRate: l.fxRate,
          card: l.card,
          categoryHint: l.categoryHint,
          isPerson: l.isPerson,
        ),
    ],
    failedChecks: s.failedChecks,
    checkCount: s.checkCount,
    warnings: s.warnings,
  );
}

List<String> _compareAccount(
  String name,
  String ref,
  List<ImportedStatement> pdf,
  List<ImportedStatement> text,
  Reveal reveal,
) {
  final pdfSpans = [for (final s in pdf) _span(s, ref)];
  final textSpans = [for (final s in text) _span(s, ref)];
  bool both(DateTime d) => _inAny(d, pdfSpans) && _inAny(d, textSpans);
  final p = [
    for (final s in pdf)
      for (final l in s.lines)
        if (l.accountRef == ref && both(l.date)) l,
  ];
  final t = [
    for (final s in text)
      for (final l in s.lines)
        if (l.accountRef == ref && both(l.date)) l,
  ];
  // Overlapping exports would count their common lines twice: pass one
  // export per account (the usual 18-month download).
  final pdfLeft = [...p], textLeft = [...t];
  final pdfCount = pdfLeft.length, textCount = textLeft.length;
  final pairs = <_Pair>[];
  void pass(Pairing how, bool Function(ImportedLine pdf, ImportedLine text) fits) {
    for (final c in [...textLeft]) {
      final i = pdfLeft.indexWhere((l) => l.amount == c.amount && fits(l, c));
      if (i < 0) continue;
      pairs.add(_Pair(pdfLeft.removeAt(i), c, how));
      textLeft.remove(c);
    }
  }

  pass(Pairing.sameDate, (a, b) => a.date == b.date);
  pass(Pairing.postedDate, (a, b) => a.postedDate != null && a.postedDate == b.date);
  for (var days = 1; days <= 3; days++) {
    pass(Pairing.nearDate, (a, b) => a.date.difference(b.date).inDays.abs() == days);
  }

  final dates = [...p, ...t].map((l) => l.date).toList()..sort();
  final o = <String>[
    '== $name: ${dates.isEmpty ? 'no common days' : '${_day(dates.first)}..${_day(dates.last)}'} '
        '(days covered by both sources)',
    '   lines: PDF $pdfCount, export $textCount; paired ${pairs.length} '
        '(${[for (final h in Pairing.values) '${h.name} ${pairs.where((x) => x.how == h).length}'].join(', ')})',
    '   unpaired: PDF ${pdfLeft.length}, export ${textLeft.length}',
  ];
  if (pdfLeft.isNotEmpty || textLeft.isNotEmpty) {
    final months = <String>{
      for (final l in [...pdfLeft, ...textLeft]) _month(l.date),
    }.toList()..sort();
    for (final m in months) {
      final a = pdfLeft.where((l) => _month(l.date) == m).length;
      final b = textLeft.where((l) => _month(l.date) == m).length;
      o.add('     $m: PDF only $a, export only $b');
    }
    final types = <String, int>{};
    for (final l in pdfLeft) {
      types.update('PDF ${l.code ?? _type(l.description, reveal)}', (n) => n + 1, ifAbsent: () => 1);
    }
    for (final l in textLeft) {
      types.update('export ${_type(l.description, reveal)}', (n) => n + 1, ifAbsent: () => 1);
    }
    o.add('   unpaired by line type:');
    o.addAll([for (final e in types.entries.toList()..sort((a, b) => b.value - a.value)) '     ${e.value}x ${e.key}']);
  }
  int sum(List<ImportedLine> ls) => ls.fold(0, (s, l) => s + l.amount);
  o.add('   totals over common days: ${sum(p) == sum(t) ? 'equal' : 'DIFFERENT'}');

  // Which export wording each PDF code comes out as.
  final types = <String, int>{};
  for (final x in pairs) {
    final key = '${x.pdf.code ?? _type(x.pdf.description, reveal)} -> "${_type(x.csv.description, reveal)}"';
    types.update(key, (n) => n + 1, ifAbsent: () => 1);
  }
  if (types.isNotEmpty) {
    // A card has no line types, only merchants: the most common are enough.
    final sorted = types.entries.toList()..sort((a, b) => b.value - a.value);
    o.add('   line types of paired lines (PDF -> export)${sorted.length > 25 ? ', 25 most common' : ''}:');
    o.addAll([for (final e in sorted.take(25)) '     ${e.value}x ${e.key}']);
  }

  // What each reader made of the same line.
  final kinds = <String, int>{};
  var sameKind = 0, sameMerchant = 0, sameHint = 0;
  for (final x in pairs) {
    if (normalizeMerchant(x.pdf.merchantText).key == normalizeMerchant(x.csv.merchantText).key) sameMerchant++;
    if (x.pdf.categoryHint == x.csv.categoryHint) sameHint++;
    if (x.pdf.kind == x.csv.kind && x.pdf.isPerson == x.csv.isPerson) {
      sameKind++;
      continue;
    }
    final key =
        'PDF ${x.pdf.code ?? _type(x.pdf.description, reveal)} ${x.pdf.kind.name}${x.pdf.isPerson ? ' (person)' : ''}'
        ' -> export "${_type(x.csv.description, reveal)}" ${x.csv.kind.name}${x.csv.isPerson ? ' (person)' : ''}';
    kinds.update(key, (n) => n + 1, ifAbsent: () => 1);
  }
  o.add(
    '   paired lines: same kind ${_of(sameKind, pairs)}, same category hint ${_of(sameHint, pairs)}, '
    'same merchant ${_of(sameMerchant, pairs)}',
  );
  if (kinds.isNotEmpty) {
    o.add('   kind differences:');
    o.addAll([for (final e in kinds.entries.toList()..sort((a, b) => b.value - a.value)) '     ${e.value}x ${e.key}']);
  }
  final merchants = {
    for (final x in pairs)
      if (normalizeMerchant(x.pdf.merchantText).key != normalizeMerchant(x.csv.merchantText).key)
        '"${maskText(x.pdf.merchantText, reveal)}" vs "${maskText(x.csv.merchantText, reveal)}"',
  }.take(8);
  if (merchants.isNotEmpty) {
    o.add('   merchant differences, accents and case aside (masked, up to 8):');
    o.addAll([for (final m in merchants) '     $m']);
  }
  return o;
}

String _of(int n, List<Object> all) => '$n of ${all.length}';
