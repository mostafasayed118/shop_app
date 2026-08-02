import '../../data/models/currency.dart';

/// Formats [amount] as a price string in [currency] (default USD), e.g.
/// `1299.5` with USD → `"$1,299.50"`, with EUR → `"€1,299.50"`.
///
/// Kept dependency-free on purpose: `intl` would be overkill for a handful of
/// symbols across a demo catalogue.
String formatPrice(double amount, {Currency currency = Currency.usd}) {
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final buffer = StringBuffer();
  for (var i = 0; i < parts[0].length; i++) {
    if (i > 0 && (parts[0].length - i) % 3 == 0) buffer.write(',');
    buffer.write(parts[0][i]);
  }
  return '${negative ? '-' : ''}${currency.symbol}$buffer.${parts[1]}';
}
