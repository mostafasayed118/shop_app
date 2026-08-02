import 'package:bloc_test/bloc_test.dart';
import 'package:e_commerce/data/models/cart_item.dart';
import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/logic/cart/cart_cubit.dart';
import 'package:e_commerce/data/repositories/cart_repository.dart';
import 'package:e_commerce/logic/cart/cart_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake of the persistence store, so persistence tests don't touch
/// the platform channel.
class _InMemoryCartRepository extends CartRepository {
  List<CartItem> stored = const [];

  @override
  Future<List<CartItem>> loadCart() async => stored;

  @override
  Future<void> saveCart(List<CartItem> items) async {
    stored = items;
  }
}

void main() {
  const headphones = Product(
    id: '1',
    name: 'Headphones',
    description: 'd',
    price: 249.99,
    imageAsset: 'assets/images/product_1.png',
    category: 'Audio',
  );
  const tee = Product(
    id: '2',
    name: 'Tee',
    description: 'd',
    price: 24.99,
    imageAsset: 'assets/images/product_7.png',
    category: 'Apparel',
  );

  group('CartCubit', () {
    test('initial state is an empty cart', () {
      expect(CartCubit().state, const CartState());
      expect(CartCubit().state.itemsCount, 0);
      expect(CartCubit().state.totalPrice, 0);
    });

    blocTest<CartCubit, CartState>(
      'addProduct merges quantities for an existing product',
      build: () => CartCubit(),
      act: (cubit) {
        cubit.addProduct(headphones, quantity: 2);
        cubit.addProduct(headphones);
      },
      expect: () => [
        const CartState(items: [CartItem(product: headphones, quantity: 2)]),
        const CartState(items: [CartItem(product: headphones, quantity: 3)]),
      ],
    );

    blocTest<CartCubit, CartState>(
      'addProduct appends different products as separate lines',
      build: () => CartCubit(),
      act: (cubit) {
        cubit.addProduct(headphones);
        cubit.addProduct(tee);
      },
      expect: () => [
        const CartState(items: [CartItem(product: headphones, quantity: 1)]),
        const CartState(
          items: [
            CartItem(product: headphones, quantity: 1),
            CartItem(product: tee, quantity: 1),
          ],
        ),
      ],
    );

    blocTest<CartCubit, CartState>(
      'incrementQuantity and decrementQuantity adjust the line',
      build: () => CartCubit(),
      act: (cubit) {
        cubit.addProduct(headphones, quantity: 2);
        cubit.incrementQuantity('1');
        cubit.decrementQuantity('1');
      },
      expect: () => [
        const CartState(items: [CartItem(product: headphones, quantity: 2)]),
        const CartState(items: [CartItem(product: headphones, quantity: 3)]),
        const CartState(items: [CartItem(product: headphones, quantity: 2)]),
      ],
    );

    blocTest<CartCubit, CartState>(
      'decrementQuantity below 1 removes the line entirely',
      build: () => CartCubit(),
      act: (cubit) {
        cubit.addProduct(tee);
        cubit.decrementQuantity('2');
      },
      expect: () => [
        const CartState(items: [CartItem(product: tee, quantity: 1)]),
        const CartState(),
      ],
    );

    blocTest<CartCubit, CartState>(
      'updateQuantity sets an absolute quantity',
      build: () => CartCubit(),
      act: (cubit) {
        cubit.addProduct(headphones);
        cubit.updateQuantity('1', 5);
      },
      expect: () => [
        const CartState(items: [CartItem(product: headphones, quantity: 1)]),
        const CartState(items: [CartItem(product: headphones, quantity: 5)]),
      ],
    );

    blocTest<CartCubit, CartState>(
      'removeProduct drops only the requested line',
      build: () => CartCubit(),
      act: (cubit) {
        cubit.addProduct(headphones);
        cubit.addProduct(tee);
        cubit.removeProduct('1');
      },
      expect: () => [
        const CartState(items: [CartItem(product: headphones, quantity: 1)]),
        const CartState(
          items: [
            CartItem(product: headphones, quantity: 1),
            CartItem(product: tee, quantity: 1),
          ],
        ),
        const CartState(items: [CartItem(product: tee, quantity: 1)]),
      ],
    );

    blocTest<CartCubit, CartState>(
      'clear empties the cart',
      build: () => CartCubit(),
      act: (cubit) {
        cubit.addProduct(headphones);
        cubit.clear();
      },
      expect: () => [
        const CartState(items: [CartItem(product: headphones, quantity: 1)]),
        const CartState(),
      ],
    );

    test('itemsCount and totalPrice stay derived from the item list', () {
      final cubit = CartCubit();
      cubit.addProduct(headphones, quantity: 2);
      cubit.addProduct(tee, quantity: 3);

      expect(cubit.state.itemsCount, 5);
      expect(cubit.state.totalPrice, closeTo(2 * 249.99 + 3 * 24.99, 0.001));

      cubit.close();
    });
  });

  group('CartCubit persistence', () {
    test('restores a previously saved cart on construction', () async {
      final repository = _InMemoryCartRepository()
        ..stored = const [CartItem(product: headphones, quantity: 2)];
      final cubit = CartCubit(repository);

      await pumpEventQueue();

      expect(cubit.state.items, const [
        CartItem(product: headphones, quantity: 2),
      ]);
      await cubit.close();
    });

    test('persists the cart after every mutation', () async {
      final repository = _InMemoryCartRepository();
      final cubit = CartCubit(repository);
      await pumpEventQueue();

      cubit.addProduct(headphones, quantity: 2);
      await pumpEventQueue();
      expect(repository.stored, const [
        CartItem(product: headphones, quantity: 2),
      ]);

      cubit.incrementQuantity('1');
      await pumpEventQueue();
      expect(repository.stored, const [
        CartItem(product: headphones, quantity: 3),
      ]);

      cubit.removeProduct('1');
      await pumpEventQueue();
      expect(repository.stored, isEmpty);

      await cubit.close();
    });

    test('a slow restore never clobbers a user action', () async {
      final repository = _InMemoryCartRepository()
        ..stored = const [CartItem(product: headphones, quantity: 1)];
      final cubit = CartCubit(repository);

      // The user adds something before the async restore completes.
      cubit.addProduct(tee);
      await pumpEventQueue();

      expect(cubit.state.items, const [CartItem(product: tee, quantity: 1)]);
      await cubit.close();
    });
  });
}
