import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/cart_repository.dart';
import 'package:e_commerce/data/repositories/catalogue_preferences_repository.dart';
import 'package:e_commerce/data/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerce/logic/cart/cart_cubit.dart';
import 'package:e_commerce/logic/products/products_cubit.dart';
import 'package:e_commerce/logic/theme/theme_cubit.dart';
import 'package:e_commerce/main.dart';
import 'package:e_commerce/ui/screens/cart_screen.dart';
import 'package:e_commerce/ui/screens/checkout_success_screen.dart';
import 'package:e_commerce/ui/screens/product_detail_screen.dart';
import 'package:e_commerce/ui/screens/products_screen.dart';
import 'package:e_commerce/ui/theme/app_theme.dart';
import 'package:e_commerce/ui/widgets/skeleton_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository that always returns an empty catalogue.
class _EmptyRepository extends ProductRepository {
  @override
  Future<List<Product>> getProducts() async => const [];
}

/// Repository that resolves instantly (microtasks only, no timers) so tests
/// never depend on the simulated-delay clock, which is order-sensitive when
/// multiple testWidgets run in the same isolate.
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
    Product(
      id: '3',
      name: 'Strider Running Sneakers',
      description: 'Responsive foam midsole.',
      price: 129.99,
      imageAsset: 'assets/images/product_3.png',
      category: 'Footwear',
    ),
    Product(
      id: '4',
      name: 'Nomad Everyday Backpack',
      description: 'Padded laptop sleeve.',
      price: 89.99,
      imageAsset: 'assets/images/product_4.png',
      category: 'Bags',
    ),
  ];
}

/// Succeeds on the first load, then fails — used to exercise the refresh-
/// failure path (keep stale grid + snackbar) without pull gestures.
class _RefreshFailRepository extends ProductRepository {
  bool _nextCallFails = false;

  @override
  Future<List<Product>> getProducts() async {
    if (_nextCallFails) {
      throw Exception('network down');
    }
    _nextCallFails = true;
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

/// Succeeds on the initial load, fails once, then succeeds again — exercises
/// the recovery path where a stale refresh-failure snackbar must be dismissed.
class _RecoveringRepository extends ProductRepository {
  int _calls = 0;

  @override
  Future<List<Product>> getProducts() async {
    _calls++;
    if (_calls == 2) {
      throw Exception('network down');
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

void main() {
  // ShopApp wires the real persistence repositories, which read
  // SharedPreferences — tests mock the store.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('browse → details → add to cart → checkout → home', (
    tester,
  ) async {
    // A realistic phone viewport: at the default 800×600 surface the search
    // bar pushes the first grid row off-screen.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ShopApp());

    // Loading: skeleton grid first (no spinner, no products yet).
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Let the simulated repository delay elapse, then settle the grid.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Catalogue loaded from the bundled JSON.
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);

    // Open product details.
    await tester.tap(find.text('Aurora Wireless Headphones'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsOneWidget);

    // Bump the quantity to 2, then add to cart.
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pump();
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    // The app-bar badge now shows 2.
    expect(find.text('2'), findsWidgets);

    // Open the cart.
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);
    // 2 × $249.99 shows as the line total and the grand total.
    expect(find.text(r'$499.98'), findsWidgets);

    // Checkout → mock success screen.
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutSuccessScreen), findsOneWidget);
    expect(find.text('Order confirmed!'), findsOneWidget);

    // Continue shopping returns to the catalogue; cart was cleared.
    await tester.tap(find.text('Continue shopping'));
    await tester.pumpAndSettle();
    expect(find.text('Shoply'), findsOneWidget);
  });

  testWidgets('shows the empty state when the catalogue has no products', (
    tester,
  ) async {
    final productsCubit = ProductsCubit(_EmptyRepository());
    await productsCubit.loadProducts();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productsCubit),
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: MaterialApp(
          theme: buildShopTheme(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No products yet'), findsOneWidget);
  });

  testWidgets('search bar and category chips filter the grid', (tester) async {
    // Same phone viewport as the other product-screen tests for consistency.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final productsCubit = ProductsCubit(_InstantRepository());
    await productsCubit.loadProducts();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productsCubit),
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: MaterialApp(
          theme: buildShopTheme(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pump();

    // All four products from _InstantRepository are listed.
    expect(find.text('Pulse Smartwatch'), findsOneWidget);

    // Typing in the search bar narrows the grid.
    await tester.enterText(find.byType(TextField), 'pulse');
    await tester.pumpAndSettle();
    expect(find.text('Pulse Smartwatch'), findsOneWidget);
    expect(find.text('Aurora Wireless Headphones'), findsNothing);

    // The clear (suffix) button restores the full grid.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);

    // A category chip filters further.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Audio'));
    await tester.pumpAndSettle();
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);
    expect(find.text('Pulse Smartwatch'), findsNothing);

    // A query that matches nothing shows the no-results state.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matches found'), findsOneWidget);

    // "Clear filters" brings the full grid back.
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);
    expect(find.text('Pulse Smartwatch'), findsOneWidget);
  });

  testWidgets('product grid renders without overflow on a phone-sized screen', (
    tester,
  ) async {
    // The default test surface is 800×600; force a real phone viewport so a
    // RenderFlex overflow in the grid tiles would fail this test.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Pre-load with an instant repository so this test never touches the
    // simulated-delay timer (which is unreliable across tests in a suite).
    final productsCubit = ProductsCubit(_InstantRepository());
    await productsCubit.loadProducts();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productsCubit),
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: MaterialApp(
          theme: buildShopTheme(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pump();

    // A RenderFlex overflow during grid layout would surface here.
    expect(tester.takeException(), isNull);
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);
  });

  testWidgets('keeps the grid and shows a snackbar when a refresh fails', (
    tester,
  ) async {
    final productsCubit = ProductsCubit(_RefreshFailRepository());
    await productsCubit.loadProducts(); // first load succeeds

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productsCubit),
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: MaterialApp(
          theme: buildShopTheme(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);

    // A failed reload keeps the grid on screen and surfaces a snackbar
    // instead of swapping to the skeleton or the full-screen error view.
    await productsCubit.loadProducts();
    await tester.pumpAndSettle();

    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);
    expect(find.byType(SkeletonGrid), findsNothing);
    expect(find.textContaining('Couldn\u2019t refresh'), findsOneWidget);

    // A second consecutive failed refresh shows the snackbar again: the cubit
    // clears the stale flag at refresh start, so the failure emits a distinct
    // state (identical states would be swallowed by Cubit).
    await tester.pump(const Duration(seconds: 5)); // let the first dismiss
    await tester.pumpAndSettle();
    expect(find.textContaining('Couldn\u2019t refresh'), findsNothing);

    await productsCubit.loadProducts(); // fails again
    await tester.pumpAndSettle();
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);
    expect(find.textContaining('Couldn\u2019t refresh'), findsOneWidget);

    // Let the snackbar's auto-dismiss timer expire before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'dismisses the refresh-failure snackbar once a refresh recovers',
    (tester) async {
      final productsCubit = ProductsCubit(_RecoveringRepository());
      await productsCubit.loadProducts(); // initial load succeeds

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: productsCubit),
            BlocProvider(create: (_) => CartCubit()),
            BlocProvider(create: (_) => ThemeCubit()),
          ],
          child: MaterialApp(
            theme: buildShopTheme(),
            home: const ProductsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aurora Wireless Headphones'), findsOneWidget);

      // A failed refresh surfaces the snackbar...
      await productsCubit.loadProducts();
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn\u2019t refresh'), findsOneWidget);

      // ...and a successful refresh dismisses the stale message.
      await productsCubit.loadProducts();
      await tester.pumpAndSettle();
      expect(find.text('Aurora Wireless Headphones'), findsOneWidget);
      expect(find.textContaining('Couldn\u2019t refresh'), findsNothing);

      // No pending snackbar timers at the end of the test.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'recovery only dismisses the refresh snackbar, not other toasts',
    (tester) async {
      // Phone viewport so the quick-add button on the card is on screen.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final productsCubit = ProductsCubit(_RecoveringRepository());
      await productsCubit.loadProducts(); // initial load succeeds

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: productsCubit),
            BlocProvider(create: (_) => CartCubit()),
            BlocProvider(create: (_) => ThemeCubit()),
          ],
          child: MaterialApp(
            theme: buildShopTheme(),
            home: const ProductsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aurora Wireless Headphones'), findsOneWidget);

      // A failed refresh surfaces the refresh snackbar...
      await productsCubit.loadProducts();
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn\u2019t refresh'), findsOneWidget);

      // ...which auto-dismisses after its duration while the flag stays set.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn\u2019t refresh'), findsNothing);

      // An unrelated toast (quick-add) is now on screen.
      await tester.tap(find.byTooltip('Add to cart').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('added to cart'), findsOneWidget);

      // A recovering refresh dismisses only the refresh snackbar — the
      // unrelated toast must survive.
      await productsCubit.loadProducts();
      await tester.pumpAndSettle();
      expect(find.textContaining('added to cart'), findsOneWidget);
      expect(find.textContaining('Couldn\u2019t refresh'), findsNothing);

      // Flush any pending snackbar timers.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('a quick-add toast queues behind the refresh-failure snackbar', (
    tester,
  ) async {
    // Phone viewport so the quick-add button on the card is on screen.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final productsCubit = ProductsCubit(_RefreshFailRepository());
    await productsCubit.loadProducts(); // initial load succeeds

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productsCubit),
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: MaterialApp(
          theme: buildShopTheme(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);

    // A failed refresh leaves the refresh-failure snackbar on screen.
    await productsCubit.loadProducts();
    await tester.pumpAndSettle();
    expect(find.textContaining('Couldn\u2019t refresh'), findsOneWidget);

    // Quick-add: the card owns its own toast, so it queues behind the
    // refresh message instead of yanking it.
    await tester.tap(find.byTooltip('Add to cart').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Couldn\u2019t refresh'), findsOneWidget);
    expect(find.textContaining('added to cart'), findsNothing);

    // Once the refresh message auto-dismisses, the queued toast appears.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('added to cart'), findsOneWidget);
    expect(find.textContaining('Couldn\u2019t refresh'), findsNothing);

    // Flush the add-to-cart toast's timer before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('sort menu reorders the grid', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final productsCubit = ProductsCubit(_InstantRepository());
    await productsCubit.loadProducts();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productsCubit),
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: MaterialApp(
          theme: buildShopTheme(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pump();

    // Open the sort menu and pick "Price: high to low".
    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();
    // warnIfMissed: the Text's center sits slightly outside the menu item's
    // InkWell hit area; the selection still registers (asserted below).
    await tester.tap(find.text('Price: high to low'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Most expensive first: Aurora ($249.99) sits above Nomad ($89.99).
    final auroraY = tester
        .getTopLeft(find.text('Aurora Wireless Headphones'))
        .dy;
    final nomadY = tester.getTopLeft(find.text('Nomad Everyday Backpack')).dy;
    expect(nomadY, greaterThan(auroraY));
  });

  testWidgets('cart survives an app restart via the persistence store', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final productsCubit = ProductsCubit(_InstantRepository());
    await productsCubit.loadProducts();

    Widget buildApp(CartCubit cartCubit) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: productsCubit),
        BlocProvider.value(value: cartCubit),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: MaterialApp(theme: buildShopTheme(), home: const ProductsScreen()),
    );

    // First "session": add an item via the card's quick-add button.
    final firstSession = CartCubit(CartRepository());
    await tester.pumpWidget(buildApp(firstSession));
    await tester.pump();
    await tester.tap(find.byTooltip('Add to cart').first);
    await tester.pumpAndSettle();

    // "Restart": tear down the tree and boot a brand-new cart over the same
    // store — the badge must come back with the saved item.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final secondSession = CartCubit(CartRepository());
    await tester.pumpWidget(buildApp(secondSession));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsWidgets);
  });

  testWidgets('cart shows a toast when an item is removed', (tester) async {
    final cartCubit = CartCubit();
    cartCubit.addProduct(
      const Product(
        id: '1',
        name: 'Aurora Wireless Headphones',
        description: 'Over-ear headphones.',
        price: 249.99,
        imageAsset: 'assets/images/product_1.png',
        category: 'Audio',
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [BlocProvider.value(value: cartCubit)],
        child: MaterialApp(theme: buildShopTheme(), home: const CartScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();

    expect(find.textContaining('removed from cart'), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);

    // Flush the snackbar timer before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('cart shows a toast when cleared', (tester) async {
    final cartCubit = CartCubit();
    cartCubit.addProduct(
      const Product(
        id: '1',
        name: 'Aurora Wireless Headphones',
        description: 'Over-ear headphones.',
        price: 249.99,
        imageAsset: 'assets/images/product_1.png',
        category: 'Audio',
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [BlocProvider.value(value: cartCubit)],
        child: MaterialApp(theme: buildShopTheme(), home: const CartScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Clear cart'));
    await tester.pumpAndSettle();

    expect(find.text('Cart cleared'), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);

    // Flush the snackbar timer before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'search and sort survive an app restart via the preferences store',
    (tester) async {
      // Phone viewport so the grid and sort menu behave like on a device.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Build the screen over a manually created cubit so the test owns both
      // "sessions" (ShopApp's own initial-load timer is order-sensitive when
      // many testWidgets share an isolate). The persistence still flows
      // through the real CataloguePreferencesRepository + mocked
      // SharedPreferences store, exactly as ShopApp wires it.
      Widget buildApp(ProductsCubit productsCubit) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productsCubit),
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: MaterialApp(
          theme: buildShopTheme(),
          home: const ProductsScreen(),
        ),
      );

      // Session 1: browse with a search query and a sort order, both of which
      // persist through the preferences repository.
      final sessionOne = ProductsCubit(
        _InstantRepository(),
        CataloguePreferencesRepository(),
      );
      await sessionOne.loadProducts();
      await tester.pumpWidget(buildApp(sessionOne));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nomad');
      await tester.pumpAndSettle();
      expect(find.text('Nomad Everyday Backpack'), findsOneWidget);
      expect(find.text('Aurora Wireless Headphones'), findsNothing);

      // Pick a sort order on top of the filtered grid.
      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: low to high'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // "Restart": tear down and boot a brand-new cubit over the same store.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      final sessionTwo = ProductsCubit(
        _InstantRepository(),
        CataloguePreferencesRepository(),
      );
      await sessionTwo.loadProducts(); // applies the saved preferences
      await tester.pumpWidget(buildApp(sessionTwo));
      await tester.pumpAndSettle();

      // The saved search text is restored and still filters the grid.
      expect(find.text('Nomad Everyday Backpack'), findsOneWidget);
      expect(find.text('Aurora Wireless Headphones'), findsNothing);

      // Clear the search: the restored sort (price low to high) is still
      // applied, so the cheapest item (Nomad, $89.99) sits above Aurora
      // ($249.99). With only four products the whole grid is built, so both
      // rows are on screen. In catalogue "featured" order Aurora would lead
      // the grid, which is what makes this a real proof of the restored sort.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Nomad Everyday Backpack'), findsOneWidget);
      expect(find.text('Aurora Wireless Headphones'), findsOneWidget);
      final nomadY = tester.getTopLeft(find.text('Nomad Everyday Backpack')).dy;
      final auroraY = tester
          .getTopLeft(find.text('Aurora Wireless Headphones'))
          .dy;
      expect(nomadY, lessThan(auroraY));
    },
  );
}
