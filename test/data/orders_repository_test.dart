import 'package:e_commerce/data/models/cart_item.dart';
import 'package:e_commerce/data/models/order.dart';
import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/orders_repository.dart';
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

  final order = Order(
    orderNumber: 'SH-123456',
    placedAt: DateTime(2026, 7, 1, 12, 30),
    items: const [CartItem(product: headphones, quantity: 2)],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OrdersRepository', () {
    test('round-trips orders through JSON', () async {
      final repository = OrdersRepository();
      await repository.saveOrders([order]);

      final loaded = await repository.loadOrders();
      expect(loaded, [order]);
      // The timestamp survives the round-trip exactly (ISO-8601 precision).
      expect(loaded.single.placedAt, DateTime(2026, 7, 1, 12, 30));
    });

    test('returns an empty history when nothing was saved', () async {
      final repository = OrdersRepository();
      expect(await repository.loadOrders(), isEmpty);
    });

    test('returns an empty history for a corrupt payload', () async {
      SharedPreferences.setMockInitialValues({'orders': 'not-json{'});

      final repository = OrdersRepository();
      expect(await repository.loadOrders(), isEmpty);
    });
  });
}
