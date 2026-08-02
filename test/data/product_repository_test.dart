import 'package:e_commerce/data/repositories/product_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductRepository', () {
    test('parses every product from the bundled JSON', () async {
      final repository = ProductRepository(delay: Duration.zero);
      final products = await repository.getProducts();

      expect(products, isNotEmpty);
      expect(products.length, greaterThanOrEqualTo(8));
      for (final product in products) {
        expect(product.id, isNotEmpty);
        expect(product.name, isNotEmpty);
        expect(product.description, isNotEmpty);
        expect(product.price, greaterThan(0));
        expect(product.imageAsset, startsWith('assets/'));
      }
    });

    test('product ids are unique', () async {
      final repository = ProductRepository(delay: Duration.zero);
      final products = await repository.getProducts();

      final ids = products.map((product) => product.id).toSet();
      expect(ids.length, products.length);
    });

    test('throws when the JSON asset cannot be loaded', () async {
      final repository = ProductRepository(
        assetPath: 'assets/data/does_not_exist.json',
        delay: Duration.zero,
      );

      // Missing assets surface as a FlutterError from the asset bundle.
      await expectLater(repository.getProducts(), throwsA(isA<FlutterError>()));
    });

    test('throws a FormatException on corrupt JSON', () async {
      final repository = ProductRepository(
        assetPath: 'assets/data/corrupt_products.json',
        delay: Duration.zero,
      );

      await expectLater(
        repository.getProducts(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
