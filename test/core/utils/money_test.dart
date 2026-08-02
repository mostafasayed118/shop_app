import 'package:e_commerce/core/utils/money.dart';
import 'package:e_commerce/data/models/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPrice', () {
    test('defaults to USD', () {
      expect(formatPrice(1299.5), r'$1,299.50');
      expect(formatPrice(9), r'$9.00');
    });

    test('formats with the chosen currency symbol', () {
      expect(formatPrice(1299.5, currency: Currency.eur), '€1,299.50');
      expect(formatPrice(1299.5, currency: Currency.gbp), '£1,299.50');
      expect(formatPrice(1299.5, currency: Currency.jpy), '¥1,299.50');
    });

    test('handles negatives and no decimal cents', () {
      expect(formatPrice(-5), r'-$5.00');
      expect(formatPrice(0), r'$0.00');
    });
  });
}
