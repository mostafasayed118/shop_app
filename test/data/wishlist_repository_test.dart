import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/wishlist_repository.dart';
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
  const tee = Product(
    id: '2',
    name: 'Breeze Cotton Tee',
    description: 'Cotton tee.',
    price: 24.99,
    imageAsset: 'assets/images/product_7.png',
    category: 'Apparel',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WishlistRepository', () {
    test('round-trips a wishlist through JSON', () async {
      final repository = WishlistRepository();
      await repository.saveWishlist(const [headphones, tee]);

      expect(await repository.loadWishlist(), const [headphones, tee]);
    });

    test('returns an empty wishlist when nothing was saved', () async {
      final repository = WishlistRepository();
      expect(await repository.loadWishlist(), isEmpty);
    });

    test('returns an empty wishlist for a corrupt payload', () async {
      SharedPreferences.setMockInitialValues({'wishlist_items': 'not-json{'});

      final repository = WishlistRepository();
      expect(await repository.loadWishlist(), isEmpty);
    });
  });
}
