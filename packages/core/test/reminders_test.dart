import 'package:core/core.dart';
import 'package:test/test.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  test('next statement end: month ends stay month ends, other days clamp', () {
    expect(nextStatementEnd(d(2026, 9, 30)), d(2026, 10, 31));
    expect(nextStatementEnd(d(2026, 1, 31)), d(2026, 2, 28));
    expect(nextStatementEnd(d(2026, 2, 28)), d(2026, 3, 31));
    expect(nextStatementEnd(d(2026, 9, 18)), d(2026, 10, 18));
    expect(nextStatementEnd(d(2026, 1, 30)), d(2026, 2, 28));
    expect(nextStatementEnd(d(2026, 12, 31)), d(2027, 1, 31));
  });

  final statements = [
    ('desjardins', 'desjardins-account', d(2026, 8, 31)),
    ('desjardins', 'desjardins-account', d(2026, 9, 30)),
    ('desjardins', 'desjardins-card', d(2026, 8, 19)),
    ('desjardins', 'desjardins-card', d(2026, 9, 18)),
  ];

  test('nothing due while the next statements are not out yet', () {
    expect(dueStatements(statements, d(2026, 10, 18)), isEmpty);
    expect(dueStatements(statements, d(2026, 10, 21)), isEmpty); // card: 3 days of grace
  });

  test('due once the next statement should be published, one entry per type', () {
    final due = dueStatements(statements, d(2026, 10, 22));
    expect(due.map((s) => (s.format, s.lastEnd, s.expectedEnd)), [
      ('desjardins-card', d(2026, 9, 18), d(2026, 10, 18)),
    ]);
    expect(dueStatements(statements, d(2026, 11, 4)).map((s) => s.format), ['desjardins-card', 'desjardins-account']);
  });
}
