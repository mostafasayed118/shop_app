import '../models/cart_item.dart';
import 'json_store.dart';

/// Persists the cart as a JSON list under a single SharedPreferences key.
///
/// Swapping to any other store later only requires reimplementing this class;
/// the rest of the app is unaware of where the cart is stored.
class CartRepository {
  static const _key = 'cart_items';

  Future<List<CartItem>> loadCart() async {
    return readStoredJson(
      _key,
      fallback: const <CartItem>[],
      decode: (json) => (json as List<dynamic>)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> saveCart(List<CartItem> items) async {
    await writeStoredJson(_key, items.map((item) => item.toJson()).toList());
  }
}
