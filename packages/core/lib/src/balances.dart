/// Account balance over time, rebuilt from the latest statement balance and
/// the transactions before it.
library;

import 'coverage.dart';
import 'kind.dart';

/// One transaction of an account: positive = money in.
class BalanceLine {
  const BalanceLine(this.date, this.amount, this.kind);

  final DateTime date;
  final int amount;
  final TransactionKind kind;
}

/// One month of an account.
class MonthBalance {
  const MonthBalance(this.month, this.closing, {this.deposits = 0, this.withdrawals = 0, this.interest = 0});

  /// First day of the month.
  final DateTime month;

  /// Balance at the end of the month.
  final int closing;

  /// Money in, interest excluded.
  final int deposits;

  /// Money out, as a positive amount.
  final int withdrawals;
  final int interest;

  int get net => deposits - withdrawals + interest;
}

/// Month-end balances from the month of the account's first line up to the
/// month of [balanceDate], oldest first. Lines after [balanceDate] are ignored
/// (not in the statement balance yet). Walking back stops before a month that
/// statements don't fully cover: balances before a missing statement are
/// unknown.
List<MonthBalance> balanceHistory({
  required int balance,
  required DateTime balanceDate,
  required List<BalanceLine> lines,
  required List<DayRange> covered,
}) {
  final last = DateTime.utc(balanceDate.year, balanceDate.month);
  if (lines.isEmpty) return [MonthBalance(last, balance)];
  final firstDay = lines.map((l) => l.date).reduce((a, b) => a.isBefore(b) ? a : b);
  final first = DateTime.utc(firstDay.year, firstDay.month);

  final flows = <DateTime, (int, int, int)>{};
  for (final l in lines) {
    if (l.date.isAfter(balanceDate)) continue;
    final m = DateTime.utc(l.date.year, l.date.month);
    final (dep, wd, interest) = flows[m] ?? (0, 0, 0);
    flows[m] = l.kind == TransactionKind.interest
        ? (dep, wd, interest + l.amount)
        : (l.amount >= 0 ? (dep + l.amount, wd, interest) : (dep, wd - l.amount, interest));
  }
  final out = <MonthBalance>[];
  var closing = balance;
  for (var m = last; !m.isBefore(first); m = DateTime.utc(m.year, m.month - 1)) {
    // The month of the balance date is known from the statement itself; older
    // months need their statement (otherwise flows are missing).
    if (m != last && covered.isNotEmpty && !monthCoverage(covered, m).full) break;
    final (dep, wd, interest) = flows[m] ?? (0, 0, 0);
    out.add(MonthBalance(m, closing, deposits: dep, withdrawals: wd, interest: interest));
    closing -= dep - wd + interest;
  }
  return out.reversed.toList();
}
