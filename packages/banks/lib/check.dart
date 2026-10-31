/// The data-free report of `banks:check` (docs/10-adding-a-bank.md §0b).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'banks.dart';
import 'plugin.dart';
import 'shape.dart';

/// What `banks:check` prints for one file: [lines] hold no statement data.
class Report {
  Report(this.ok, this.lines);
  final bool ok;
  final List<String> lines;
}

/// Reads the statement [load] returns with the plug-in of [registry] that
/// recognizes it, everything it prints swallowed, and describes the result
/// without statement data.
Report checkStatement(StatementInput Function() load, Reveal r, {List<BankImporter> registry = banks}) {
  final captured = Swallow();
  try {
    final read = readQuietly(load, captured, registry: registry);
    if (read == null) return Report(false, ['not recognized by any registered bank', ...captured.note]);
    return _describe(read.statement, r, captured, unchecked: read.unchecked);
  } on Object catch (e, stack) {
    final message = switch (e) {
      FormatException(:final message) => 'FormatException: ${maskText(message, r)}',
      _ => '${e.runtimeType}',
    };
    return Report(false, [
      'ERROR $message',
      for (final f in stack.toString().split('\n'))
        if (f.contains('package:banks/')) 'at ${f.substring(f.indexOf('package:banks/')).replaceAll(')', '')}',
      ...captured.note,
    ]);
  }
}

/// The statement [load] returns, read by the plug-in of [registry] that
/// recognizes it, with everything it prints counted in [captured] and hidden;
/// null when no plug-in recognizes it. [unchecked]: its format has nothing to
/// check for this file type (`StatementFormat.uncheckedFileTypes`).
({ImportedStatement statement, String fileType, bool unchecked})? readQuietly(
  StatementInput Function() load,
  Swallow captured, {
  List<BankImporter> registry = banks,
}) => IOOverrides.runZoned(
  () => runZoned(() {
    final input = load();
    for (final b in registry) {
      final format = b.detect(input);
      if (format == null) continue;
      return (
        statement: b.read(input),
        fileType: input.fileType,
        unchecked: b.format(format)?.uncheckedFileTypes.contains(input.fileType) ?? false,
      );
    }
    return null;
  }, zoneSpecification: ZoneSpecification(print: (_, _, _, _) => captured.count++)),
  stdout: () => captured,
  stderr: () => captured,
);

Report _describe(ImportedStatement s, Reveal r, Swallow captured, {required bool unchecked}) {
  String d(DateTime x) => x.toIso8601String().substring(0, 10);
  final kinds = <String, int>{};
  for (final l in s.lines) {
    kinds.update(l.kind.name, (n) => n + 1, ifAbsent: () => 1);
  }
  final refs = {for (final a in s.accounts) a.ref};
  final odd = {
    'zero amounts': s.lines.where((l) => l.amount == 0).length,
    'empty descriptions': s.lines.where((l) => l.description.trim().isEmpty).length,
    'lines of an undeclared account': s.lines.where((l) => !refs.contains(l.accountRef)).length,
    'dates after the period': s.lines.where((l) => l.date.isAfter(s.periodEnd.add(const Duration(days: 1)))).length,
    'dates 62+ days before the period': s.lines
        .where((l) => l.date.isBefore(s.periodStart.subtract(const Duration(days: 62))))
        .length,
  }..removeWhere((_, n) => n == 0);
  final ok = s.isValid && s.warnings.isEmpty && (s.checkCount > 0 || unchecked) && odd.isEmpty;
  return Report(ok, [
    '${s.format} ${d(s.periodStart)}..${d(s.periodEnd)} '
        '${s.isValid ? 'VALID (${s.checkCount} checks)' : 'INVALID (${s.failedChecks.length} of ${s.checkCount} checks failed)'}',
    'accounts: ${[for (final a in s.accounts) '${a.type.name} ${a.currency} (${s.lines.where((l) => l.accountRef == a.ref).length} lines, closing balance ${a.closingBalance == null ? 'unknown' : 'known'})'].join(', ')}',
    'kinds: ${[for (final MapEntry(:key, :value) in kinds.entries) '$key=$value'].join(' ')}',
    'money in: ${s.lines.where((l) => l.amount > 0).length} lines, out: ${s.lines.where((l) => l.amount < 0).length} lines',
    if (s.checkCount == 0 && unchecked) 'not verified: nothing to check in this file type',
    if (s.checkCount == 0 && !unchecked) 'no self-checks: add balance / total checks',
    for (final MapEntry(:key, :value) in odd.entries) 'suspicious: $value $key',
    for (final c in s.failedChecks) 'FAILED ${maskText(c, r)}',
    for (final w in s.warnings) 'warning ${maskText(w, r)}',
    ...captured.note,
  ]);
}

/// Stands in for stdout / stderr while a plug-in runs: counts lines, keeps nothing.
class Swallow implements Stdout {
  int count = 0;

  List<String> get note => [if (count > 0) 'the plug-in printed $count time(s): hidden (remove debug prints)'];

  @override
  void write(Object? object) => count++;
  @override
  void writeln([Object? object = '']) => count++;
  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) => count++;
  @override
  void writeCharCode(int charCode) => count++;
  @override
  void add(List<int> data) => count++;
  @override
  Encoding encoding = utf8;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
