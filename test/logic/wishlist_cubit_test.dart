import 'package:bloc_test/bloc_test.dart';
import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/wishlist_repository.dart';
import 'package:e_commerce/logic/wishlist/wishlist_cubit.dart';
import 'package:e_commerce/logic/wishlist/wishlist_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake of the persistence store, so persistence tests don't touch
/// the platform channel.
class _InMemoryWishlistRepository extends WishlistRepository {
  List<Product> stored = const [];

  @override
  Future<List<Product>> loadWishlist() async => stored;

  @override
  Future<void> saveWishlist(List<Product> products) async {
    stored = products;
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

  group('WishlistCubit', () {
    test('initial state is an empty wishlist', () {
      final cubit = WishlistCubit();
      expect(cubit.state, const WishlistState());
      expect(cubit.state.isEmpty, isTrue);
      expect(cubit.contains('1'), isFalse);
      cubit.close();
    });

    blocTest<WishlistCubit, WishlistState>(
      'toggle adds a product that is not yet saved',
      build: () => WishlistCubit(),
      act: (cubit) => cubit.toggle(headphones),
      expect: () => [
        const WishlistState(products: [headphones]),
      ],
    );

    blocTest<WishlistCubit, WishlistState>(
      'toggle again removes a saved product',
      build: () => WishlistCubit(),
      act: (cubit) {
        cubit.toggle(headphones);
        cubit.toggle(headphones);
      },
      expect: () => [
        const WishlistState(products: [headphones]),
        const WishlistState(),
      ],
    );

    blocTest<WishlistCubit, WishlistState>(
      'toggle appends different products in order',
      build: () => WishlistCubit(),
      act: (cubit) {
        cubit.toggle(headphones);
        cubit.toggle(tee);
      },
      expect: () => [
        const WishlistState(products: [headphones]),
        const WishlistState(products: [headphones, tee]),
      ],
    );

    blocTest<WishlistCubit, WishlistState>(
      'remove drops only the requested product',
      build: () => WishlistCubit(),
      act: (cubit) {
        cubit.toggle(headphones);
        cubit.toggle(tee);
        cubit.remove('1');
      },
      expect: () => [
        const WishlistState(products: [headphones]),
        const WishlistState(products: [headphones, tee]),
        const WishlistState(products: [tee]),
      ],
    );

    blocTest<WishlistCubit, WishlistState>(
      'remove of an unsaved product is a no-op',
      build: () => WishlistCubit(),
      act: (cubit) => cubit.remove('999'),
      expect: () => const [],
    );

    blocTest<WishlistCubit, WishlistState>(
      'clear empties the wishlist',
      build: () => WishlistCubit(),
      act: (cubit) {
        cubit.toggle(headphones);
        cubit.clear();
      },
      expect: () => [
        const WishlistState(products: [headphones]),
        const WishlistState(),
      ],
    );

    test('contains reflects the saved products', () {
      final cubit = WishlistCubit();
      cubit.toggle(headphones);
      cubit.toggle(tee);

      expect(cubit.contains('1'), isTrue);
      expect(cubit.contains('2'), isTrue);
      expect(cubit.contains('3'), isFalse);

      cubit.close();
    });
  });

  group('WishlistCubit persistence', () {
    test('restores a previously saved wishlist on construction', () async {
      final repository = _InMemoryWishlistRepository()
        ..stored = const [headphones, tee];
      final cubit = WishlistCubit(repository);

      await pumpEventQueue();

      expect(cubit.state.products, const [headphones, tee]);
      await cubit.close();
    });

    test('persists the wishlist after every mutation', () async {
      final repository = _InMemoryWishlistRepository();
      final cubit = WishlistCubit(repository);
      await pumpEventQueue();

      cubit.toggle(headphones);
      await pumpEventQueue();
      expect(repository.stored, const [headphones]);

      cubit.toggle(tee);
      await pumpEventQueue();
      expect(repository.stored, const [headphones, tee]);

      cubit.remove('1');
      await pumpEventQueue();
      expect(repository.stored, const [tee]);

      cubit.clear();
      await pumpEventQueue();
      expect(repository.stored, isEmpty);

      await cubit.close();
    });

    test('a slow restore never clobbers a user action', () async {
      final repository = _InMemoryWishlistRepository()
        ..stored = const [headphones];
      final cubit = WishlistCubit(repository);

      // The user toggles before the async restore completes.
      cubit.toggle(tee);
      await pumpEventQueue();

      expect(cubit.state.products, const [tee]);
      await cubit.close();
    });
  });
}
