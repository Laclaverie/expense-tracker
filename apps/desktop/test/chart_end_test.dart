import 'package:expense_desktop/screens/dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime m(int y, int mo) => DateTime.utc(y, mo);
  final latest = DateTime.utc(2026, 9, 29);

  test('the dashboard chart stays on the latest data while the selected month is inside it', () {
    expect(chartEnd(m(2026, 9), latest), m(2026, 9));
    expect(chartEnd(m(2026, 3), latest), m(2026, 9));
    expect(chartEnd(m(2025, 10), latest), m(2026, 9)); // first month of the window
  });

  test('moves back by whole years before the window, forward to an empty current month', () {
    expect(chartEnd(m(2025, 9), latest), m(2025, 9));
    expect(chartEnd(m(2024, 10), latest), m(2025, 9));
    expect(chartEnd(m(2024, 9), latest), m(2024, 9));
    expect(chartEnd(m(2026, 10), latest), m(2026, 10));
    expect(chartEnd(m(2026, 10), null), m(2026, 10));
  });
}
