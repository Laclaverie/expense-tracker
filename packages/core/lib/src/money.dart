/// Formats integer cents for display: `-1 234,56 $` (fr) or `-$1,234.56` (en).
String formatMoney(int cents, String currency, {String languageCode = 'fr'}) {
  final negative = cents < 0;
  final abs = cents.abs();
  final fr = languageCode == 'fr';
  final units = (abs ~/ 100).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => fr ? ' ' : ',');
  final number = '$units${fr ? ',' : '.'}${(abs % 100).toString().padLeft(2, '0')}';
  final symbol = switch (currency) {
    'CAD' => '\$',
    'EUR' => '€',
    'USD' => 'US\$',
    _ => currency,
  };
  final sign = negative ? '-' : '';
  return fr ? '$sign$number $symbol' : '$sign$symbol$number';
}
