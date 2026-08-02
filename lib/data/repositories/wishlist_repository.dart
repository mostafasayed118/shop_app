import '../models/product.dart';
import 'json_store.dart';

/// Persists the wishlist as a JSON list of product snapshots under a single
/// SharedPreferences key.
///
/// Mirrors the cart's store contract: full product snapshots are saved, so a
/// persisted wishlist can be restored without depending on the catalogue
/// having loaded first.
class WishlistRepository {
  static const _key = 'wishlist_items';

  Future<List<Product>> loadWishlist() async {
    return readStoredJson(
      _key,
      fallback: const <Product>[],
      decode: (json) => (json as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> saveWishlist(List<Product> products) async {
    await writeStoredJson(_key, products.map((p) => p.toJson()).toList());
  }
}
