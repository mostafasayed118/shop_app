import 'package:e_commerce/data/models/cart_item.dart';
import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/cart_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const headphones = Product(
    id: '1',
    name: 'Aurora Wireless Headphones',
    description: 'Over-ear headphones.',
    price: 249.99,
    imageAsset: 'assets/images/product_1.png',
    category: 'Audio',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CartRepository', () {
    test('round-trips a cart through JSON', () async {
      final repository = CartRepository();
      await repository.saveCart(const [
        CartItem(product: headphones, quantity: 2),
      ]);

      expect(await repository.loadCart(), const [
        CartItem(product: headphones, quantity: 2),
      ]);
    });

    test('returns an empty cart when nothing was saved', () async {
      final repository = CartRepository();
      expect(await repository.loadCart(), isEmpty);
    });

    test('returns an empty cart for a corrupt payload', () async {
      SharedPreferences.setMockInitialValues({'cart_items': 'not-json{'});

      final repository = CartRepository();
      expect(await repository.loadCart(), isEmpty);
    });
  });
}
