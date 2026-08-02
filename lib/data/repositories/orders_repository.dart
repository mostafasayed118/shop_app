import '../models/order.dart';
import 'json_store.dart';

/// Persists completed orders as a JSON list under a single SharedPreferences
/// key. Each order carries full item snapshots, so history can be restored
/// without depending on the catalogue or the cart.
class OrdersRepository {
  static const _key = 'orders';

  Future<List<Order>> loadOrders() async {
    return readStoredJson(
      _key,
      fallback: const <Order>[],
      decode: (json) => (json as List<dynamic>)
          .map((order) => Order.fromJson(order as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> saveOrders(List<Order> orders) async {
    await writeStoredJson(_key, orders.map((order) => order.toJson()).toList());
  }
}
