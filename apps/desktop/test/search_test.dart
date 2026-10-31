import 'package:expense_desktop/search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime.utc(2026, 10, 12);
  bool find(String q, {List<String?> text = const ['ACME CORP', 'Achat /ACME CORP', null], int cents = -4250}) =>
      SearchQuery.parse(q).matches(text: text, cents: cents, date: date);

  test('text: every word, accents and case ignored', () {
    expect(find('acme'), isTrue);
    expect(find('ACME achat'), isTrue);
    expect(find('acme epicerie'), isFalse);
    expect(find('epicerie', text: const ['Épicerie du coin']), isTrue);
    expect(find(''), isFalse);
  });

  test('amounts: exact with decimals, whole dollars without', () {
    expect([find('42,50'), find('42.50'), find('42.5'), find(r'42,50 $'), find('-42,50')], everyElement(isTrue));
    expect(find('42,51'), isFalse);
    expect(find('42'), isTrue);
    expect(find('43'), isFalse);
    expect(find('7', text: const ['7-ELEVEN 7'], cents: -100), isTrue); // the text 7
  });

  test('dates: ISO prefix or day/month', () {
    expect([find('2026-10'), find('2026-10-12'), find('12/10'), find('12/10/2026')], everyElement(isTrue));
    expect([find('2026-09'), find('10/12'), find('12/10/2025')], everyElement(isFalse));
    expect(find('acme 2026-10 42,50'), isTrue);
  });
}
