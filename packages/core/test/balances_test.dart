import 'package:core/core.dart';
import 'package:test/test.dart';

BalanceLine line(int y, int m, int d, int amount, [TransactionKind kind = TransactionKind.transfer]) =>
    BalanceLine(DateTime.utc(y, m, d), amount, kind);

void main() {
  final lines = [
    line(2024, 9, 27, 100000),
    line(2024, 9, 30, 16, TransactionKind.interest),
    line(2024, 10, 7, 20000),
    line(2024, 10, 31, 381, TransactionKind.interest),
    line(2024, 12, 5, -50000),
    line(2024, 12, 31, 300, TransactionKind.interest),
  ];
  final covered = <DayRange>[(DateTime.utc(2024, 9), DateTime.utc(2024, 12, 31))];

  test('walks back from the statement balance; deposits, withdrawals, interest per month', () {
    final h = balanceHistory(balance: 70697, balanceDate: DateTime.utc(2024, 12, 31), lines: lines, covered: covered);
    expect(h.map((b) => b.month.month), [9, 10, 11, 12]);
    expect(h.map((b) => b.closing), [100016, 120397, 120397, 70697]);
    expect((h.first.deposits, h.first.interest), (100000, 16));
    expect((h.last.withdrawals, h.last.interest, h.last.net), (50000, 300, -49700));
  });

  test('stops before a month without statement; ignores lines after the balance date', () {
    final gap = <DayRange>[
      (DateTime.utc(2024, 9), DateTime.utc(2024, 10, 31)),
      (DateTime.utc(2024, 12), DateTime.utc(2024, 12, 31)),
    ];
    final h = balanceHistory(
      balance: 70697,
      balanceDate: DateTime.utc(2024, 12, 31),
      lines: [...lines, line(2025, 1, 6, 80000)],
      covered: gap,
    );
    expect(h.map((b) => b.month.month), [12]);
    expect(h.single.closing, 70697);
  });

  test('no lines: only the current balance', () {
    final h = balanceHistory(balance: 500, balanceDate: DateTime.utc(2026, 9, 30), lines: const [], covered: covered);
    expect((h.single.month, h.single.closing), (DateTime.utc(2026, 9), 500));
  });
}
