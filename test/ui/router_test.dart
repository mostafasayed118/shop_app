import 'package:e_commerce/data/models/cart_item.dart';
import 'package:e_commerce/data/models/order.dart';
import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/orders_repository.dart';
import 'package:e_commerce/data/repositories/product_repository.dart';
import 'package:e_commerce/logic/cart/cart_cubit.dart';
import 'package:e_commerce/logic/orders/orders_cubit.dart';
import 'package:e_commerce/logic/products/products_cubit.dart';
import 'package:e_commerce/logic/settings/settings_cubit.dart';
import 'package:e_commerce/logic/theme/theme_cubit.dart';
import 'package:e_commerce/logic/wishlist/wishlist_cubit.dart';
import 'package:e_commerce/main.dart';
import 'package:e_commerce/ui/router/app_router.dart';
import 'package:e_commerce/ui/screens/cart_screen.dart';
import 'package:e_commerce/ui/screens/not_found_screen.dart';
import 'package:e_commerce/ui/screens/order_detail_screen.dart';
import 'package:e_commerce/ui/screens/product_detail_screen.dart';
import 'package:e_commerce/ui/screens/products_screen.dart';
import 'package:e_commerce/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository that resolves instantly (microtasks only, no timers).
/// Fails the first load, succeeds afterwards — exercises the deep-link retry
/// path (catalogue error → "Try again" → product resolves).
/// Returns a different catalogue on the second load, so a refresh emits a
/// genuinely new Loaded state (identical ones are swallowed by the cubit) —
/// used to prove a refresh doesn't rebuild the resolved detail screen.
class _RefreshingRepository extends ProductRepository {
  int _calls = 0;

  @override
  Future<List<Product>> getProducts() async {
    _calls++;
    if (_calls == 1) {
      return const [
        Product(
          id: '1',
          name: 'Aurora Wireless Headphones',
          description: 'Over-ear headphones.',
          price: 249.99,
          imageAsset: 'assets/images/product_1.png',
          category: 'Audio',
        ),
      ];
    }
    return const [
      Product(
        id: '1',
        name: 'Aurora Wireless Headphones',
        description: 'Over-ear headphones.',
        price: 249.99,
        imageAsset: 'assets/images/product_1.png',
        category: 'Audio',
      ),
      Product(
        id: '2',
        name: 'Pulse Smartwatch',
        description: 'Always-on display.',
        price: 199.99,
        imageAsset: 'assets/images/product_2.png',
        category: 'Wearables',
      ),
    ];
  }
}

class _RetryRepository extends ProductRepository {
  int _calls = 0;

  @override
  Future<List<Product>> getProducts() async {
    _calls++;
    if (_calls == 1) throw Exception('network down');
    return const [
      Product(
        id: '1',
        name: 'Aurora Wireless Headphones',
        description: 'Over-ear headphones.',
        price: 249.99,
        imageAsset: 'assets/images/product_1.png',
        category: 'Audio',
      ),
    ];
  }
}

/// Orders repository whose restore takes a beat, so a deep link can arrive
/// while the history is still loading — the race the resolver must survive.
class _SlowOrdersRepository extends OrdersRepository {
  @override
  Future<List<Order>> loadOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return [
      Order(
        orderNumber: 'SH-7',
        placedAt: DateTime(2026, 7, 1),
        items: const [CartItem(product: _headphones, quantity: 1)],
      ),
    ];
  }

  @override
  Future<void> saveOrders(List<Order> orders) async {}
}

class _InstantRepository extends ProductRepository {
  @override
  Future<List<Product>> getProducts() async => const [
    Product(
      id: '1',
      name: 'Aurora Wireless Headphones',
      description: 'Over-ear headphones.',
      price: 249.99,
      imageAsset: 'assets/images/product_1.png',
      category: 'Audio',
    ),
    Product(
      id: '2',
      name: 'Pulse Smartwatch',
      description: 'Always-on display.',
      price: 199.99,
      imageAsset: 'assets/images/product_2.png',
      category: 'Wearables',
    ),
  ];
}

const _headphones = Product(
  id: '1',
  name: 'Aurora Wireless Headphones',
  description: 'Over-ear headphones.',
  price: 249.99,
  imageAsset: 'assets/images/product_1.png',
  category: 'Audio',
);

void main() {
  // The ShopApp-level test wires real persistence repositories, which read
  // SharedPreferences — tests mock the store.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProductsCubit> loadProducts() async {
    final cubit = ProductsCubit(_InstantRepository());
    await cubit.loadProducts();
    return cubit;
  }

  /// Hosts the real router over the three cubits, starting at
  /// [initialLocation] so a test can boot straight into a deep link.
  Widget buildApp(
    ProductsCubit productsCubit, {
    String initialLocation = '/',
    OrdersCubit? ordersCubit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: productsCubit),
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider(create: (_) => WishlistCubit()),
        BlocProvider.value(value: ordersCubit ?? OrdersCubit()),
        BlocProvider(create: (_) => SettingsCubit()),
      ],
      child: MaterialApp.router(
        routerConfig: createAppRouter(initialLocation: initialLocation),
        theme: buildShopTheme(),
      ),
    );
  }

  testWidgets('deep link to /product/:id resolves via the catalogue', (
    tester,
  ) async {
    final productsCubit = await loadProducts();
    addTearDown(productsCubit.close);

    await tester.pumpWidget(
      buildApp(productsCubit, initialLocation: '/product/1'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text('Aurora Wireless Headphones'), findsWidgets);
  });

  testWidgets('deep link to an unknown product id shows the not-found screen', (
    tester,
  ) async {
    final productsCubit = await loadProducts();
    addTearDown(productsCubit.close);

    await tester.pumpWidget(
      buildApp(productsCubit, initialLocation: '/product/999'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundScreen), findsOneWidget);
    expect(find.text('Page not found'), findsOneWidget);
  });

  testWidgets(
    'a deep link arriving mid-load waits and resolves once the catalogue loads',
    (tester) async {
      // The catalogue is deliberately NOT loaded yet when the deep link boots.
      final productsCubit = ProductsCubit(_InstantRepository());
      addTearDown(productsCubit.close);

      await tester.pumpWidget(
        buildApp(productsCubit, initialLocation: '/product/1'),
      );
      // A single frame only: the resolver's spinner animates forever, so
      // pumpAndSettle would time out while it's on screen.
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ProductDetailScreen), findsNothing);
      expect(find.byType(NotFoundScreen), findsNothing);

      // The catalogue lands; the resolver swaps the spinner for the detail.
      await productsCubit.loadProducts();
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Aurora Wireless Headphones'), findsWidgets);
      expect(find.byType(NotFoundScreen), findsNothing);
    },
  );

  testWidgets(
    'a deep link with a failed catalogue offers retry, then resolves',
    (tester) async {
      final productsCubit = ProductsCubit(_RetryRepository());
      addTearDown(productsCubit.close);

      await tester.pumpWidget(
        buildApp(productsCubit, initialLocation: '/product/1'),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // The first load attempt fails → a retry-able error view (not "not
      // found"), because the catalogue itself never loaded.
      await productsCubit.loadProducts();
      await tester.pumpAndSettle();
      expect(find.text('Could not load products'), findsOneWidget);
      expect(find.byType(NotFoundScreen), findsNothing);

      // Retrying succeeds, and the resolver then opens the product.
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailScreen), findsOneWidget);
    },
  );

  testWidgets(
    'a catalogue refresh after resolving does not reset the detail screen',
    (tester) async {
      final productsCubit = ProductsCubit(_RefreshingRepository());
      await productsCubit.loadProducts(); // first load: single product
      addTearDown(productsCubit.close);

      await tester.pumpWidget(
        buildApp(productsCubit, initialLocation: '/product/1'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailScreen), findsOneWidget);

      // Bump the quantity stepper — internal StatefulWidget state that a
      // rebuild would reset.
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      // A refresh emits a new Loaded state (different catalogue). The
      // resolver's buildWhen must suppress the rebuild so the open detail
      // screen keeps its state.
      await productsCubit.loadProducts();
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets('deep link to /orders/:number opens the order detail', (
    tester,
  ) async {
    final ordersCubit = OrdersCubit();
    ordersCubit.recordOrder(
      Order(
        orderNumber: 'SH-7',
        placedAt: DateTime(2026, 7, 1),
        items: const [CartItem(product: _headphones, quantity: 1)],
      ),
    );
    addTearDown(ordersCubit.close);
    final productsCubit = await loadProducts();
    addTearDown(productsCubit.close);

    await tester.pumpWidget(
      buildApp(
        productsCubit,
        ordersCubit: ordersCubit,
        initialLocation: '/orders/SH-7',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(find.text('SH-7'), findsOneWidget);
  });

  testWidgets('deep link to an unknown order number shows not found', (
    tester,
  ) async {
    final ordersCubit = OrdersCubit();
    addTearDown(ordersCubit.close);
    final productsCubit = await loadProducts();
    addTearDown(productsCubit.close);

    await tester.pumpWidget(
      buildApp(
        productsCubit,
        ordersCubit: ordersCubit,
        initialLocation: '/orders/UNKNOWN',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  testWidgets(
    'a deep link arriving while orders restore waits, then resolves',
    (tester) async {
      // The history is deliberately NOT restored yet when the deep link
      // boots: the resolver must show a spinner, not "not found".
      final ordersCubit = OrdersCubit(_SlowOrdersRepository());
      addTearDown(ordersCubit.close);
      final productsCubit = await loadProducts();
      addTearDown(productsCubit.close);

      await tester.pumpWidget(
        buildApp(
          productsCubit,
          ordersCubit: ordersCubit,
          initialLocation: '/orders/SH-7',
        ),
      );
      // A single frame only: the resolver's spinner animates forever, so
      // pumpAndSettle would time out while it's on screen.
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(OrderDetailScreen), findsNothing);
      expect(find.byType(NotFoundScreen), findsNothing);

      // The restore lands; the resolver swaps the spinner for the detail.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(find.text('SH-7'), findsOneWidget);
      expect(find.byType(NotFoundScreen), findsNothing);
    },
  );

  testWidgets('an unmatched route shows not found and back to shop returns home', (
    tester,
  ) async {
    final productsCubit = await loadProducts();
    addTearDown(productsCubit.close);

    await tester.pumpWidget(buildApp(productsCubit, initialLocation: '/nope'));
    await tester.pumpAndSettle();
    expect(find.byType(NotFoundScreen), findsOneWidget);

    await tester.tap(find.text('Back to shop'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductsScreen), findsOneWidget);
  });

  testWidgets('in-app navigation flows through the router', (tester) async {
    // ShopApp uses the real repository (with its simulated load delay), so
    // mirror the timing used by the other ShopApp-level tests.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ShopApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Catalogue home is the initial route.
    expect(find.byType(ProductsScreen), findsOneWidget);

    // The app-bar cart button pushes /cart through the router.
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsOneWidget);

    // A product tap pushes /product/:id with the product as extra.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aurora Wireless Headphones'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });
}
