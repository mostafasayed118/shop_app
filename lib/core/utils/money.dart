/// Formats [amount] as a USD price string, e.g. `1299.5` → `"$1,299.50"`.
///
/// Kept dependency-free on purpose: `intl` would be overkill for a single
/// currency across a demo catalogue.
String formatPrice(double amount) {
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final buffer = StringBuffer();
  for (var i = 0; i < parts[0].length; i++) {
    if (i > 0 && (parts[0].length - i) % 3 == 0) buffer.write(',');
    buffer.write(parts[0][i]);
  }
  return '${negative ? '-' : ''}\$$buffer.${parts[1]}';
}
