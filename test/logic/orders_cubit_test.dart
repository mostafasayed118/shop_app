import 'package:bloc_test/bloc_test.dart';
import 'package:e_commerce/data/models/cart_item.dart';
import 'package:e_commerce/data/models/order.dart';
import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/orders_repository.dart';
import 'package:e_commerce/logic/orders/orders_cubit.dart';
import 'package:e_commerce/logic/orders/orders_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake of the persistence store, so persistence tests don't touch
/// the platform channel.
class _InMemoryOrdersRepository extends OrdersRepository {
  List<Order> stored = const [];

  @override
  Future<List<Order>> loadOrders() async => stored;

  @override
  Future<void> saveOrders(List<Order> orders) async {
    stored = orders;
  }
}

void main() {
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

  Order order(String number, {List<CartItem> items = const []}) => Order(
    orderNumber: number,
    placedAt: DateTime(2026, 7, 1),
    items: items,
  );

  group('Order', () {
    test('totals are derived from the item lines', () {
      final o = order('SH-1', items: const [
        CartItem(product: headphones, quantity: 2),
        CartItem(product: tee, quantity: 3),
      ]);
      expect(o.itemCount, 5);
      expect(o.total, closeTo(2 * 249.99 + 3 * 24.99, 0.001));
    });
  });

  group('OrdersCubit', () {
    test('initial state is an empty history', () {
      final cubit = OrdersCubit();
      expect(cubit.state, const OrdersState());
      expect(cubit.state.isEmpty, isTrue);
      cubit.close();
    });

    blocTest<OrdersCubit, OrdersState>(
      'recordOrder prepends the new order (most recent first)',
      build: () => OrdersCubit(),
      act: (cubit) {
        cubit.recordOrder(order('SH-1'));
        cubit.recordOrder(order('SH-2'));
      },
      expect: () => [
        OrdersState(orders: [order('SH-1')]),
        OrdersState(orders: [order('SH-2'), order('SH-1')]),
      ],
    );

    blocTest<OrdersCubit, OrdersState>(
      'clear empties the history',
      build: () => OrdersCubit(),
      act: (cubit) {
        cubit.recordOrder(order('SH-1'));
        cubit.clear();
      },
      expect: () => [
        OrdersState(orders: [order('SH-1')]),
        const OrdersState(),
      ],
    );
  });

  group('OrdersCubit persistence', () {
    test('restores a previously saved history on construction', () async {
      final repository = _InMemoryOrdersRepository()
        ..stored = [order('SH-1'), order('SH-2')];
      final cubit = OrdersCubit(repository);

      await pumpEventQueue();

      expect(cubit.state.orders.map((o) => o.orderNumber), ['SH-1', 'SH-2']);
      await cubit.close();
    });

    test('persists the history after every mutation', () async {
      final repository = _InMemoryOrdersRepository();
      final cubit = OrdersCubit(repository);
      await pumpEventQueue();

      cubit.recordOrder(order('SH-1'));
      await pumpEventQueue();
      expect(repository.stored.single.orderNumber, 'SH-1');

      cubit.recordOrder(order('SH-2'));
      await pumpEventQueue();
      expect(
        repository.stored.map((o) => o.orderNumber),
        ['SH-2', 'SH-1'],
      );

      cubit.clear();
      await pumpEventQueue();
      expect(repository.stored, isEmpty);

      await cubit.close();
    });

    test('a slow restore never clobbers a user action', () async {
      final repository = _InMemoryOrdersRepository()
        ..stored = [order('SH-1')];
      final cubit = OrdersCubit(repository);

      // The user records an order before the async restore completes.
      cubit.recordOrder(order('SH-2'));
      await pumpEventQueue();

      expect(cubit.state.orders.map((o) => o.orderNumber), ['SH-2']);
      await cubit.close();
    });
  });
}
