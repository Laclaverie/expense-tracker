/// Facts about the columns of a CSV export, computed on the owner's machine
/// and shown at the top of its shape: what each column holds, line order,
/// which column is a running balance. Only counts, column numbers and masked
/// formats: no value of the file. Saves the agent from guessing them from
/// masked lines.
library;

import 'plugin.dart';

/// Kind of value most filled cells of a column hold.
enum _Kind { date, amount, integer, text }

final _integer = RegExp(r'^-?\d+$');

_Kind _kindOf(String v) {
  if (parseCsvDate(v) != null || parseCsvDate(v, dayFirst: false) != null) return _Kind.date;
  if (parseCsvCents(v) != null) return _Kind.amount;
  if (_integer.hasMatch(v.trim())) return _Kind.integer;
  return _Kind.text;
}

/// `9999/99/99`-style pattern of a date field and which part is the day.
String _dateFormat(Iterable<String> values) {
  final sample = values.first.trim();
  final sep = RegExp(r'[/.-]').firstMatch(sample)![0]!;
  final parts = sample.split(sep);
  if (parts[0].length == 4) return 'YYYY${sep}MM${sep}DD';
  // Year last: the day is the part that goes above 12 somewhere.
  final firstAbove12 = values.any((v) => (int.tryParse(v.trim().split(sep)[0]) ?? 0) > 12);
  final secondAbove12 = values.any((v) => (int.tryParse(v.trim().split(sep)[1]) ?? 0) > 12);
  if (firstAbove12) return 'DD${sep}MM${sep}YYYY';
  if (secondAbove12) return 'MM${sep}DD${sep}YYYY';
  return '??$sep??${sep}YYYY (day and month never above 12: order unknown)';
}

/// The fact lines for a CSV / TXT export [input], `# `-prefixed; empty for
/// other inputs or when the lines don't split into columns.
List<String> csvFacts(TextInput input) {
  if (input.fileType != 'csv' && input.fileType != 'txt') return const [];
  final lines = input.lines;
  final sep = guessCsvSeparator(lines);
  final rows = [for (final l in lines) splitCsvLine(l, separator: sep)];
  final widths = <int, int>{};
  for (final r in rows) {
    widths.update(r.length, (n) => n + 1, ifAbsent: () => 1);
  }
  final columns = widths.keys.reduce((a, b) => a > b ? a : b);
  if (columns < 2) return const [];

  final sepName = switch (sep) {
    ',' => 'comma',
    ';' => 'semicolon',
    '\t' => 'tab',
    _ => "'$sep'",
  };
  final out = <String>[
    'Facts computed on the original file (counts and formats only, no value):',
    'separator: $sepName; columns per line: ${[for (final e in widths.entries) '${e.key} (${e.value} lines)'].join(', ')}',
  ];

  // A first line with no date or amount where later lines have some: a header.
  final kinds = [
    for (final r in rows) [for (final v in r) v.trim().isEmpty ? null : _kindOf(v)],
  ];
  final header =
      rows.length > 1 && kinds.first.every((k) => k == null || k == _Kind.text) && kinds[1].any((k) => k == _Kind.date);
  out.add(header ? 'line 1 looks like a header (no date, later lines have one)' : 'no header line');
  final body = header ? rows.sublist(1) : rows;
  final bodyKinds = header ? kinds.sublist(1) : kinds;

  int? dateColumn;
  final amountColumns = <int>[];
  final columnKinds = <_Kind?>[];
  for (var c = 0; c < columns; c++) {
    final values = [
      for (final r in body)
        if (c < r.length && r[c].trim().isNotEmpty) r[c],
    ];
    final counts = <_Kind, int>{};
    for (final k in bodyKinds) {
      if (c < k.length && k[c] != null) counts.update(k[c]!, (n) => n + 1, ifAbsent: () => 1);
    }
    final name = 'col ${c + 1}';
    if (values.isEmpty) {
      out.add('$name: empty on every line');
      columnKinds.add(null);
      continue;
    }
    final kind = counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    columnKinds.add(kind);
    final distinct = values.toSet().length;
    final filled = values.length == body.length ? 'every line' : '${values.length} of ${body.length} lines';
    final others = values.length - counts[kind]!;
    final mixed = others > 0 ? ', $others other values' : '';
    final desc = switch (kind) {
      _Kind.date => 'date ${_dateFormat(values.where((v) => _kindOf(v) == _Kind.date))}',
      _Kind.amount =>
        'amount, ${values.where((v) => (parseCsvCents(v) ?? 0) < 0).length} negative, '
            '${values.where((v) => parseCsvCents(v) == 0).length} zero',
      _Kind.integer => 'integer',
      _Kind.text => 'text',
    };
    final same = distinct == 1 ? ', same value on every filled line' : ', $distinct distinct values';
    out.add('$name: $desc$mixed, filled on $filled$same');
    if (kind == _Kind.date) dateColumn ??= c;
    if (kind == _Kind.amount) amountColumns.add(c);
    if (kind == _Kind.integer && distinct > 1) out.add('  ${_sequence(body, c)}');
  }

  // A column with a few values, each on one run of consecutive lines, splits
  // the file into blocks (one per account): order and balance are per block.
  final blocks = _blocks(body, columnKinds);
  if (blocks.column != null) {
    out.add(
      'lines grouped by col ${blocks.column! + 1}: ${blocks.runs.length} blocks of consecutive lines, one per value',
    );
  }
  if (dateColumn != null) {
    final dc = dateColumn;
    final orders = [
      for (final run in blocks.runs)
        _order([for (final r in run) parseCsvDate(dc < r.length ? r[dc] : '')].nonNulls.toList()),
    ];
    out.add('line order (col ${dc + 1}): ${orders.toSet().join(' / ')}${blocks.runs.length > 1 ? ' (per block)' : ''}');
  }
  out.add(_balance(blocks.runs, amountColumns, dateColumn));
  return [for (final l in out) '# $l'];
}

({int? column, List<List<List<String>>> runs}) _blocks(List<List<String>> body, List<_Kind?> kinds) {
  String at(List<String> r, int c) => c < r.length ? r[c] : '';
  for (var c = 0; c < kinds.length; c++) {
    if (kinds[c] != _Kind.text && kinds[c] != _Kind.integer) continue;
    final runs = <List<List<String>>>[];
    for (final r in body) {
      if (runs.isEmpty || at(runs.last.last, c) != at(r, c)) runs.add([]);
      runs.last.add(r);
    }
    final values = {for (final run in runs) at(run.first, c)};
    if (runs.length > 1 && runs.length <= 12 && values.length == runs.length) return (column: c, runs: runs);
  }
  return (column: null, runs: [body]);
}

String _order(List<DateTime> dates) {
  var up = 0, down = 0;
  for (var i = 1; i < dates.length; i++) {
    final c = dates[i].compareTo(dates[i - 1]);
    if (c > 0) up++;
    if (c < 0) down++;
  }
  if (up == 0 && down == 0) return 'all lines on one date';
  if (down == 0) return 'oldest first';
  if (up == 0) return 'newest first';
  return '$up steps forward, $down backward (several blocks, e.g. one per account?)';
}

String _sequence(List<List<String>> body, int c) {
  final values = [
    for (final r in body)
      if (c < r.length) int.tryParse(r[c].trim()),
  ].nonNulls.toList();
  var up = 0, down = 0;
  for (var i = 1; i < values.length; i++) {
    if (values[i] > values[i - 1]) up++;
    if (values[i] < values[i - 1]) down++;
  }
  final unique = values.toSet().length == values.length ? 'unique' : '${values.length - values.toSet().length} repeats';
  return '$unique; between consecutive lines: $up increase, $down decrease';
}

/// Line orders the balance search tries inside each block.
enum _Order {
  oldestFirst('oldest line first'),
  newestFirst('newest line first'),
  daysOldestFirstLinesReversed('days oldest first, lines of a day newest first'),
  daysNewestFirstLinesReversed('days newest first, lines of a day oldest first');

  const _Order(this.label);
  final String label;
}

/// [run] in time order according to [order] (by the date in [dateColumn]
/// for the per-day orders).
List<List<String>> _inTime(List<List<String>> run, _Order order, int? dateColumn) {
  List<List<List<String>>> days() {
    final out = <List<List<String>>>[];
    for (final r in run) {
      final d = dateColumn != null && dateColumn < r.length ? r[dateColumn] : '';
      final lastDate = out.isEmpty || dateColumn == null ? null : out.last.last[dateColumn];
      if (out.isEmpty || lastDate != d) out.add([]);
      out.last.add(r);
    }
    return out;
  }

  return switch (order) {
    _Order.oldestFirst => run,
    _Order.newestFirst => run.reversed.toList(),
    _Order.daysOldestFirstLinesReversed => [for (final d in days()) ...d.reversed],
    _Order.daysNewestFirstLinesReversed => [for (final d in days().reversed) ...d.reversed],
  };
}

/// Searches a running balance: a column B where, between consecutive lines in
/// time, B changes by a signed sum of other amount columns (empty = 0) of the
/// later line (B is the balance after each line) or of the earlier one (B is
/// the balance before it), for several line orders. Reports the best formula
/// and how many line pairs hold; when none holds for half of them, the best
/// tries, so a reader of the facts can tell what the column isn't.
String _balance(List<List<List<String>>> runs, List<int> amountColumns, int? dateColumn) {
  const none = 'running balance: none found';
  final body = runs.expand((r) => r).toList();
  if (amountColumns.length < 2 || body.length < 3) return none;
  int cents(List<String> r, int c) => c < r.length ? parseCsvCents(r[c]) ?? 0 : 0;
  final tries = <({int b, List<(int, int)> terms, _Order order, bool before, int ok})>[];
  for (final b in amountColumns) {
    if (body.where((r) => b < r.length && parseCsvCents(r[b]) != null).length < body.length * 0.9) continue;
    final others = [
      for (final c in amountColumns)
        if (c != b) c,
    ].take(6).toList();
    // Every sign (−1, 0, +1) for each other column, as a base-3 number.
    final combos = others.fold(1, (n, _) => n * 3);
    for (final order in _Order.values) {
      final timed = [for (final run in runs) _inTime(run, order, dateColumn)];
      for (final before in const [false, true]) {
        ({int b, List<(int, int)> terms, _Order order, bool before, int ok})? best;
        for (var combo = 1; combo < combos; combo++) {
          final terms = <(int, int)>[];
          for (var i = 0, v = combo; i < others.length; i++, v ~/= 3) {
            if (v % 3 != 1) terms.add((others[i], v % 3 - 1));
          }
          var ok = 0;
          for (final run in timed) {
            for (var i = 1; i < run.length; i++) {
              final (prev, next) = (run[i - 1], run[i]);
              final moved = before ? prev : next;
              final delta = terms.fold(0, (s, t) => s + t.$2 * cents(moved, t.$1));
              if (cents(next, b) - cents(prev, b) == delta) ok++;
            }
          }
          if (best == null || ok > best.ok || (ok == best.ok && terms.length < best.terms.length)) {
            best = (b: b, terms: terms, order: order, before: before, ok: ok);
          }
        }
        if (best != null) tries.add(best);
      }
    }
  }
  if (tries.isEmpty) return none;
  // Ties: "newest first, after" and "oldest first, before" (signs flipped) fit the same
  // numbers; "after" reads naturally.
  tries.sort((a, b) => a.ok != b.ok ? b.ok - a.ok : (a.before ? 1 : 0) - (b.before ? 1 : 0));
  final pairs = body.length - runs.length;
  String describe(({int b, List<(int, int)> terms, _Order order, bool before, int ok}) t) {
    final formula = [for (final (c, sign) in t.terms) '${sign > 0 ? '+' : '-'} col ${c + 1}'].join(' ');
    return "col ${t.b + 1} = previous line's col ${t.b + 1} $formula "
        '(${t.order.label}, balance ${t.before ? 'before' : 'after'} the line): ${t.ok} of $pairs consecutive pairs hold';
  }

  if (tries.first.ok >= pairs / 2) return 'running balance: ${describe(tries.first)}';
  return ['$none; best tries:', for (final t in tries.take(4)) '  ${describe(t)}'].join('\n# ');
}
