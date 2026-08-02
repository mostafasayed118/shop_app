import 'package:e_commerce/ui/widgets/product_grid.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('product grid geometry', () {
    test('the padding matches the grid contract', () {
      expect(kProductGridPadding, const EdgeInsets.all(16));
    });

    test('the delegate carries the shared tile geometry', () {
      final delegate = productGridDelegate(4);
      expect(delegate.crossAxisCount, 4);
      expect(delegate.mainAxisSpacing, 16);
      expect(delegate.crossAxisSpacing, 16);
      expect(delegate.childAspectRatio, 0.6);
    });
  });
}
