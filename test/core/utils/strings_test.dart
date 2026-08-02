import 'package:e_commerce/core/utils/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pluralize', () {
    test('keeps the singular for exactly one', () {
      expect(pluralize(1, 'item'), '1 item');
    });

    test('adds an "s" for zero or many', () {
      expect(pluralize(0, 'item'), '0 items');
      expect(pluralize(2, 'item'), '2 items');
      expect(pluralize(10, 'item'), '10 items');
    });

    test('supports an irregular plural', () {
      expect(pluralize(2, 'box', plural: 'boxes'), '2 boxes');
      expect(pluralize(1, 'box', plural: 'boxes'), '1 box');
    });
  });
}
