import 'package:banks/src/desjardins/pdf/text.dart';
import 'package:test/test.dart';

void main() {
  test('parseCents handles both decimal styles, minus and CR', () {
    expect(parseCents('1753.48'), 175348);
    expect(parseCents('0.01-'), -1);
    expect(parseCents('2948,64'), 294864);
    expect(parseCents('2799,20CR'), 279920);
    expect(parseCents('3,00'), 300);
  });

  test('inferDate puts later months in the previous year', () {
    final end = DateTime.utc(2026, 1, 20);
    expect(inferDate(19, 12, end), DateTime.utc(2025, 12, 19));
    expect(inferDate(5, 1, end), DateTime.utc(2026, 1, 5));
  });

  test('formatCents', () {
    expect(formatCents(-294864), '-2 948,64');
    expect(formatCents(5), '0,05');
    expect(formatCents(123456789), '1 234 567,89');
  });
}
