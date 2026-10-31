import 'package:core/core.dart';

/// One line without personal data: format, period, counts, validation.
String summarize(ImportedStatement s) {
  String d(DateTime x) => x.toIso8601String().substring(0, 10);
  final failed = s.failedChecks.length;
  return '${s.format} ${d(s.periodStart)}..${d(s.periodEnd)} '
      'accounts=${s.accounts.map((a) => '${a.type.name}:${s.lines.where((l) => l.accountRef == a.ref).length}').join(',')} '
      '${failed == 0 ? 'VALID (${s.checkCount} checks)' : 'INVALID ($failed of ${s.checkCount} checks failed)'}'
      '${s.warnings.isEmpty ? '' : ' — ${s.warnings.join('; ')}'}';
}

/// Dates, amounts, kinds and check counts — everything except text. Two
/// statements with the same fingerprint parse identically (used to prove an
/// anonymized fixture still parses like the original).
String fingerprint(ImportedStatement s) => [
  s.format,
  '${s.periodStart}|${s.periodEnd}|${s.coversSincePrevious}',
  for (final a in s.accounts) '${a.type}|${a.currency}|${a.closingBalance}',
  for (final l in s.lines) '${l.date}|${l.postedDate}|${l.amount}|${l.kind}|${l.code}|${l.categoryHint}|${l.isPerson}',
  '${s.checkCount}|${s.failedChecks.length}',
].join('\n');
