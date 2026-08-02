import 'package:bloc_test/bloc_test.dart';
import 'package:e_commerce/data/models/catalogue_preferences.dart';
import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/catalogue_preferences_repository.dart';
import 'package:e_commerce/data/repositories/product_repository.dart';
import 'package:e_commerce/logic/products/products_cubit.dart';
import 'package:e_commerce/logic/products/products_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProductRepository extends Mock implements ProductRepository {}

/// In-memory fake of the preferences store for persistence tests.
class _FakePreferencesRepository extends CataloguePreferencesRepository {
  _FakePreferencesRepository(this.stored);

  CataloguePreferences? stored;

  @override
  Future<CataloguePreferences?> load() async => stored;

  @override
  Future<void> save(CataloguePreferences preferences) async {
    stored = preferences;
  }
}

void main() {
  const product = Product(
    id: '1',
    name: 'Aurora Wireless Headphones',
    description: 'Over-ear headphones.',
    price: 249.99,
    imageAsset: 'assets/images/product_1.png',
    category: 'Audio',
  );
  const secondProduct = Product(
    id: '3',
    name: 'Pulse Smartwatch',
    description: 'Always-on display.',
    price: 199.99,
    imageAsset: 'assets/images/product_2.png',
    category: 'Wearables',
  );
  const tee = Product(
    id: '2',
    name: 'Breeze Cotton Tee',
    description: 'Cotton tee.',
    price: 24.99,
    imageAsset: 'assets/images/product_7.png',
    category: 'Apparel',
  );

  group('ProductsCubit', () {
    late _MockProductRepository repository;

    setUp(() {
      repository = _MockProductRepository();
    });

    test('initial state is ProductsInitial', () {
      expect(ProductsCubit(repository).state, isA<ProductsInitial>());
    });

    blocTest<ProductsCubit, ProductsState>(
      'emits Loading then Loaded with products on success',
      build: () {
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product]);
        return ProductsCubit(repository);
      },
      act: (cubit) => cubit.loadProducts(),
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>().having((state) => state.products, 'products', [
          product,
        ]),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'updateQuery narrows the loaded list and keeps the category',
      build: () {
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product, tee]);
        return ProductsCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProducts();
        cubit.updateQuery('head');
      },
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>(),
        isA<ProductsLoaded>()
            .having((state) => state.query, 'query', 'head')
            .having((state) => state.filteredProducts, 'filtered', [product]),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'selectCategory narrows the loaded list',
      build: () {
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product, tee]);
        return ProductsCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProducts();
        cubit.selectCategory('Apparel');
      },
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>(),
        isA<ProductsLoaded>()
            .having((state) => state.selectedCategory, 'category', 'Apparel')
            .having((state) => state.filteredProducts, 'filtered', [tee]),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'emits Loaded with an empty list when the catalogue is empty',
      build: () {
        when(() => repository.getProducts()).thenAnswer((_) async => const []);
        return ProductsCubit(repository);
      },
      act: (cubit) => cubit.loadProducts(),
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>().having(
          (state) => state.products,
          'products',
          isEmpty,
        ),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'emits Loading then Error when the repository throws',
      build: () {
        when(
          () => repository.getProducts(),
        ).thenThrow(Exception('network down'));
        return ProductsCubit(repository);
      },
      act: (cubit) => cubit.loadProducts(),
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsError>().having(
          (state) => state.message,
          'message',
          isNotEmpty,
        ),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'keeps the loaded list visible during a refresh (no Loading emission)',
      build: () {
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product]);
        return ProductsCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProducts();
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product, secondProduct]);
        await cubit.loadProducts();
      },
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>().having((state) => state.products, 'products', [
          product,
        ]),
        isA<ProductsLoaded>().having((state) => state.products, 'products', [
          product,
          secondProduct,
        ]),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'keeps the stale list and flags refreshFailed when a refresh fails',
      build: () {
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product]);
        return ProductsCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProducts();
        when(
          () => repository.getProducts(),
        ).thenThrow(Exception('network down'));
        await cubit.loadProducts();
      },
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>()
            .having((state) => state.products, 'products', [product])
            .having((state) => state.refreshFailed, 'refreshFailed', false),
        isA<ProductsLoaded>()
            .having((state) => state.products, 'products', [product])
            .having((state) => state.refreshFailed, 'refreshFailed', true),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'a later successful refresh clears the refreshFailed flag',
      build: () {
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product]);
        return ProductsCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProducts();
        when(
          () => repository.getProducts(),
        ).thenThrow(Exception('network down'));
        await cubit.loadProducts();
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product, secondProduct]);
        await cubit.loadProducts();
      },
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>()
            .having((state) => state.products, 'products', [product])
            .having((state) => state.refreshFailed, 'refreshFailed', false),
        isA<ProductsLoaded>()
            .having((state) => state.products, 'products', [product])
            .having((state) => state.refreshFailed, 'refreshFailed', true),
        // The third load clears the stale flag at refresh start, then the
        // success lands fresh data (flag stays false).
        isA<ProductsLoaded>()
            .having((state) => state.products, 'products', [product])
            .having((state) => state.refreshFailed, 'refreshFailed', false),
        isA<ProductsLoaded>()
            .having((state) => state.products, 'products', [
              product,
              secondProduct,
            ])
            .having((state) => state.refreshFailed, 'refreshFailed', false),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'a consecutive failed refresh re-surfaces the refreshFailed state',
      build: () {
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product]);
        return ProductsCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProducts();
        when(
          () => repository.getProducts(),
        ).thenThrow(Exception('network down'));
        await cubit.loadProducts(); // refresh 1 fails
        await cubit.loadProducts(); // refresh 2 fails
      },
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>().having(
          (state) => state.refreshFailed,
          'refreshFailed',
          false,
        ),
        isA<ProductsLoaded>().having(
          (state) => state.refreshFailed,
          'refreshFailed',
          true,
        ),
        // Refresh 2 resets the flag at start, so its failure emits again
        // instead of being swallowed as an identical state.
        isA<ProductsLoaded>().having(
          (state) => state.refreshFailed,
          'refreshFailed',
          false,
        ),
        isA<ProductsLoaded>().having(
          (state) => state.refreshFailed,
          'refreshFailed',
          true,
        ),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'setSort updates the sort configuration and reorders',
      build: () {
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product, tee]);
        return ProductsCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProducts();
        cubit.setSort(SortField.price, SortDirection.descending);
      },
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>(),
        isA<ProductsLoaded>()
            .having((state) => state.sortField, 'sortField', SortField.price)
            .having(
              (state) => state.sortDirection,
              'sortDirection',
              SortDirection.descending,
            )
            .having((state) => state.sortedProducts, 'sorted', [product, tee]),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'a refresh preserves the sort configuration',
      build: () {
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product, tee]);
        return ProductsCubit(repository);
      },
      act: (cubit) async {
        await cubit.loadProducts();
        cubit.setSort(SortField.name, SortDirection.descending);
        // Return different products on refresh so the refreshed state is not
        // equatable-identical to the current one (Cubit skips identical
        // emissions) — this proves the refresh ran AND kept the sort.
        when(
          () => repository.getProducts(),
        ).thenAnswer((_) async => const [product, tee, secondProduct]);
        await cubit.loadProducts(); // refresh
      },
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>(),
        isA<ProductsLoaded>()
            .having((state) => state.sortField, 'sortField', SortField.name)
            .having(
              (state) => state.sortDirection,
              'sortDirection',
              SortDirection.descending,
            ),
        isA<ProductsLoaded>()
            .having((state) => state.sortField, 'sortField', SortField.name)
            .having(
              (state) => state.sortDirection,
              'sortDirection',
              SortDirection.descending,
            )
            .having((state) => state.products, 'products', [
              product,
              tee,
              secondProduct,
            ]),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'applies saved preferences to the initial load',
      build: () {
        when(() => repository.getProducts())
            .thenAnswer((_) async => const [product, tee]);
        final prefs = _FakePreferencesRepository(
          const CataloguePreferences(
            query: 'head',
            category: 'Audio',
            sortField: SortField.price,
            sortDirection: SortDirection.descending,
          ),
        );
        return ProductsCubit(repository, prefs);
      },
      act: (cubit) => cubit.loadProducts(),
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsLoaded>()
            .having((state) => state.query, 'query', 'head')
            .having((state) => state.selectedCategory, 'category', 'Audio')
            .having((state) => state.sortField, 'sortField', SortField.price)
            .having(
              (state) => state.sortDirection,
              'sortDirection',
              SortDirection.descending,
            ),
      ],
    );

    test('persists preferences when filters or sort change', () async {
      when(() => repository.getProducts())
          .thenAnswer((_) async => const [product, tee]);
      final prefs = _FakePreferencesRepository(null);
      final cubit = ProductsCubit(repository, prefs);

      await cubit.loadProducts();
      cubit.updateQuery('tee');
      cubit.setSort(SortField.name, SortDirection.descending);
      await pumpEventQueue();

      expect(prefs.stored?.query, 'tee');
      expect(prefs.stored?.sortField, SortField.name);
      expect(prefs.stored?.sortDirection, SortDirection.descending);

      await cubit.close();
    });

    test('falls back to defaults when no preferences are saved', () async {
      when(() => repository.getProducts())
          .thenAnswer((_) async => const [product]);
      final prefs = _FakePreferencesRepository(null);
      final cubit = ProductsCubit(repository, prefs);

      await cubit.loadProducts();

      final loaded = cubit.state as ProductsLoaded;
      expect(loaded.query, '');
      expect(loaded.selectedCategory, isNull);
      expect(loaded.sortField, SortField.featured);

      await cubit.close();
    });
  });
}
