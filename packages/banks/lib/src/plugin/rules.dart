import 'package:core/core.dart';

/// Which way the money goes, seen from the account.
enum Direction { any, moneyOut, moneyIn }

/// One row of a bank's classification table: which lines it matches and what
/// they are. A table is a `const List<LineRule>`; the first matching row wins,
/// so put specific rows (a code with a description) before general ones (the
/// code alone).
///
/// ```dart
/// LineRule(codes: {'DI'}, startsWith: 'Paie', kind: TransactionKind.income, hint: 'income.salary'),
/// LineRule(codes: {'DI'}, kind: TransactionKind.income, hint: 'income.other'),
/// ```
class LineRule {
  const LineRule({
    this.codes = const {},
    this.section,
    this.startsWith,
    this.contains,
    this.direction = Direction.any,
    required this.kind,
    this.hint,
    this.isPerson = false,
  });

  /// Transaction codes this row applies to; empty = any code (or none).
  final Set<String> codes;

  /// Part of the statement the line was printed in (e.g. a card statement's
  /// `operations` vs `purchases`), when the parser passes one; null = any.
  final String? section;

  /// Description starts with / contains this text, ignoring case and accents
  /// (one export writes `AccèsD`, another `AccesD`).
  final String? startsWith;
  final String? contains;
  final Direction direction;

  final TransactionKind kind;

  /// Category id the line implies (see `docs/10-adding-a-bank.md`).
  final String? hint;

  /// Money sent to or received from a person, not a business.
  final bool isPerson;

  bool matches({String? code, String? section, required String description, required int amount}) {
    if (codes.isNotEmpty && !codes.contains(code)) return false;
    if (this.section != null && this.section != section) return false;
    final d = stripAccents(description);
    if (startsWith != null && !d.startsWith(stripAccents(startsWith!))) return false;
    if (contains != null && !d.contains(stripAccents(contains!))) return false;
    return switch (direction) {
      Direction.any => true,
      Direction.moneyOut => amount < 0,
      Direction.moneyIn => amount > 0,
    };
  }
}

/// What a line is, and which rule said so (null = no rule matched).
class Classification {
  const Classification(this.kind, {this.hint, this.isPerson = false, this.rule});

  final TransactionKind kind;
  final String? hint;
  final bool isPerson;
  final LineRule? rule;

  bool get matched => rule != null;
}

/// Applies a rule table to the lines of one statement and remembers the lines
/// no rule matched: they fall back to `expense` (money out) / `refund` (money
/// in), which is usually wrong for an unknown code (a deposit would lower
/// spending), so they are reported in [warnings] (→ `ImportedStatement.warnings`).
class LineClassifier {
  LineClassifier(this.rules);

  final List<LineRule> rules;
  final _unmatched = <String, int>{};

  /// [unmatchedKey] names the line in [warnings] when no rule matches
  /// (default: its code); it must hold no personal data.
  Classification classify({
    String? code,
    String? section,
    required String description,
    required int amount,
    String? unmatchedKey,
  }) {
    for (final r in rules) {
      if (r.matches(code: code, section: section, description: description, amount: amount)) {
        return Classification(r.kind, hint: r.hint, isPerson: r.isPerson, rule: r);
      }
    }
    final key = unmatchedKey ?? code ?? '(no code${section == null ? '' : ', section $section'})';
    _unmatched.update(key, (n) => n + 1, ifAbsent: () => 1);
    return Classification(amount < 0 ? TransactionKind.expense : TransactionKind.refund);
  }

  /// `unknown code XYZ (3 lines): counted as expense / refund` — no personal data.
  List<String> get warnings => [
    for (final MapEntry(key: code, value: n) in _unmatched.entries)
      'unknown code $code ($n line${n == 1 ? '' : 's'}): counted as expense / refund',
  ];
}
