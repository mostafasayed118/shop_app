import 'package:e_commerce/data/models/currency.dart';
import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/product_repository.dart';
import 'package:e_commerce/data/models/cart_item.dart';
import 'package:e_commerce/data/models/order.dart';
import 'package:e_commerce/logic/cart/cart_cubit.dart';
import 'package:e_commerce/logic/cart/cart_state.dart';
import 'package:e_commerce/logic/orders/orders_cubit.dart';
import 'package:e_commerce/logic/products/products_cubit.dart';
import 'package:e_commerce/logic/products/products_state.dart';
import 'package:e_commerce/logic/settings/settings_cubit.dart';
import 'package:e_commerce/logic/theme/theme_cubit.dart';
import 'package:e_commerce/logic/wishlist/wishlist_cubit.dart';
import 'package:e_commerce/ui/router/app_router.dart';
import 'package:e_commerce/ui/screens/orders_screen.dart';
import 'package:e_commerce/ui/screens/settings_screen.dart';
import 'package:e_commerce/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository that resolves instantly (microtasks only, no timers) so tests
/// never depend on the simulated-delay clock.
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
      name: 'Breeze Cotton Tee',
      description: 'Cotton tee.',
      price: 24.99,
      imageAsset: 'assets/images/product_7.png',
      category: 'Apparel',
    ),
  ];
}

const _product = Product(
  id: '1',
  name: 'Aurora Wireless Headphones',
  description: 'Over-ear headphones.',
  price: 249.99,
  imageAsset: 'assets/images/product_1.png',
  category: 'Audio',
);

void main() {
  Future<ProductsCubit> loadProducts() async {
    final cubit = ProductsCubit(_InstantRepository());
    await cubit.loadProducts();
    return cubit;
  }

  /// Mirrors ShopApp's wiring (theme mode reacts to ThemeCubit) but hosts the
  /// settings screen so a test can drive the cubits directly.
  Widget buildApp({
    required ThemeCubit themeCubit,
    required ProductsCubit productsCubit,
    required CartCubit cartCubit,
    WishlistCubit? wishlistCubit,
    OrdersCubit? ordersCubit,
    SettingsCubit? settingsCubit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: themeCubit),
        BlocProvider.value(value: productsCubit),
        BlocProvider.value(value: cartCubit),
        BlocProvider.value(value: wishlistCubit ?? WishlistCubit()),
        BlocProvider.value(value: ordersCubit ?? OrdersCubit()),
        BlocProvider.value(value: settingsCubit ?? SettingsCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        // Hosted on the real router so the order-history tile's `context.push`
        // resolves; the router boots straight into the settings screen.
        builder: (context, mode) => MaterialApp.router(
          theme: buildShopTheme(),
          darkTheme: buildShopTheme(brightness: Brightness.dark),
          themeMode: mode,
          routerConfig: createAppRouter(initialLocation: '/settings'),
        ),
      ),
    );
  }

  /// A tall viewport so every settings section (including the bottom tiles)
  /// is on screen without scrolling.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('currency selector switches the display currency and persists', (
    tester,
  ) async {
    // A phone-width viewport: the four currency segments must fit without
    // overflowing (the theme control proves three at this width; four short
    // ISO codes must too).
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settingsCubit = SettingsCubit();
    addTearDown(settingsCubit.close);

    await tester.pumpWidget(
      buildApp(
        themeCubit: ThemeCubit(),
        productsCubit: await loadProducts(),
        cartCubit: CartCubit(),
        settingsCubit: settingsCubit,
      ),
    );
    await tester.pumpAndSettle();

    // The four segments render without a RenderFlex overflow.
    expect(tester.takeException(), isNull);
    for (final code in ['USD', 'EUR', 'GBP', 'JPY']) {
      expect(find.text(code), findsOneWidget);
    }

    // Default is USD; picking EUR lands on the cubit.
    expect(settingsCubit.state, Currency.usd);
    await tester.tap(find.text('EUR'));
    await tester.pumpAndSettle();
    expect(settingsCubit.state, Currency.eur);

    // Switching back to USD works too.
    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();
    expect(settingsCubit.state, Currency.usd);
  });

  testWidgets('theme selector switches the app theme and persists', (
    tester,
  ) async {
    useTallViewport(tester);
    final themeCubit = ThemeCubit();
    addTearDown(themeCubit.close);

    await tester.pumpWidget(
      buildApp(
        themeCubit: themeCubit,
        productsCubit: await loadProducts(),
        cartCubit: CartCubit(),
      ),
    );
    await tester.pumpAndSettle();

    // Default is system → resolves to the (light) platform brightness.
    ThemeData themeOf() =>
        Theme.of(tester.element(find.byType(SettingsScreen)));
    expect(themeOf().brightness, Brightness.light);

    // Pick Dark: the theme flips and the choice lands on the cubit.
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(themeCubit.state, ThemeMode.dark);
    expect(themeOf().brightness, Brightness.dark);

    // Pick System again: back to following the platform.
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(themeCubit.state, ThemeMode.system);
    expect(themeOf().brightness, Brightness.light);
  });

  testWidgets('clear cart is disabled when the cart is empty', (tester) async {
    useTallViewport(tester);

    await tester.pumpWidget(
      buildApp(
        themeCubit: ThemeCubit(),
        productsCubit: await loadProducts(),
        cartCubit: CartCubit(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cart is empty'), findsOneWidget);
    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Clear cart'),
    );
    expect(tile.enabled, isFalse);
  });

  testWidgets('clear cart asks for confirmation, then clears and toasts', (
    tester,
  ) async {
    useTallViewport(tester);
    final cartCubit = CartCubit();
    cartCubit.addProduct(_product);
    addTearDown(cartCubit.close);

    await tester.pumpWidget(
      buildApp(
        themeCubit: ThemeCubit(),
        productsCubit: await loadProducts(),
        cartCubit: cartCubit,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 item in cart'), findsOneWidget);

    // Cancel keeps the cart untouched.
    await tester.tap(find.text('Clear cart'));
    await tester.pumpAndSettle();
    expect(find.text('Clear cart?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(cartCubit.state.items, isNotEmpty);

    // Confirm empties the cart and shows the toast.
    await tester.tap(find.text('Clear cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(cartCubit.state, const CartState());
    expect(find.text('Cart cleared'), findsOneWidget);
    expect(find.text('Cart is empty'), findsOneWidget);

    // Flush the snackbar timer before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('reset saved filters asks for confirmation, then resets', (
    tester,
  ) async {
    useTallViewport(tester);
    final productsCubit = await loadProducts();
    productsCubit.updateQuery('tee'); // non-default config → tile enabled
    addTearDown(productsCubit.close);

    await tester.pumpWidget(
      buildApp(
        themeCubit: ThemeCubit(),
        productsCubit: productsCubit,
        cartCubit: CartCubit(),
      ),
    );
    await tester.pumpAndSettle();

    // A non-default config enables the tile.
    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Reset saved filters'),
    );
    expect(tile.enabled, isTrue);

    await tester.tap(find.text('Reset saved filters'));
    await tester.pumpAndSettle();
    expect(find.text('Reset saved filters?'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect((productsCubit.state as ProductsLoaded).query, '',
      reason: 'search text is cleared',
    );
    expect(find.text('Catalogue filters reset'), findsOneWidget);

    // Flush the snackbar timer before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('reset saved filters is disabled when nothing is customized', (
    tester,
  ) async {
    useTallViewport(tester);

    await tester.pumpWidget(
      buildApp(
        themeCubit: ThemeCubit(),
        productsCubit: await loadProducts(),
        cartCubit: CartCubit(),
      ),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Reset saved filters'),
    );
    expect(tile.enabled, isFalse);
  });

  testWidgets(
    'reset all data clears cart, filters and theme but keeps order history',
    (tester) async {
    useTallViewport(tester);
    final themeCubit = ThemeCubit();
    themeCubit.setThemeMode(ThemeMode.dark);
    final productsCubit = await loadProducts();
    productsCubit.updateQuery('tee');
    final cartCubit = CartCubit();
    cartCubit.addProduct(_product);
    final wishlistCubit = WishlistCubit();
    wishlistCubit.toggle(_product);
    final ordersCubit = OrdersCubit();
    ordersCubit.recordOrder(
      Order(
        orderNumber: 'SH-1',
        placedAt: DateTime(2026, 7, 1),
        items: const [CartItem(product: _product, quantity: 1)],
      ),
    );
    final settingsCubit = SettingsCubit();
    settingsCubit.setCurrency(Currency.eur);
    addTearDown(themeCubit.close);
    addTearDown(productsCubit.close);
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);
    addTearDown(ordersCubit.close);
    addTearDown(settingsCubit.close);

    await tester.pumpWidget(
      buildApp(
        themeCubit: themeCubit,
        productsCubit: productsCubit,
        cartCubit: cartCubit,
        wishlistCubit: wishlistCubit,
        ordersCubit: ordersCubit,
        settingsCubit: settingsCubit,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset all data'));
    await tester.pumpAndSettle();
    expect(find.text('Reset all data?'), findsOneWidget);
    await tester.tap(find.text('Reset all'));
    await tester.pumpAndSettle();

    expect(cartCubit.state, const CartState());
    expect(wishlistCubit.state.isEmpty, isTrue);
    // Purchase history deliberately survives a data reset.
    expect(ordersCubit.state.orders, hasLength(1));
    expect((productsCubit.state as ProductsLoaded).query, '');
    expect(themeCubit.state, ThemeMode.system);
    expect(settingsCubit.state, Currency.usd);
    expect(find.text('All data reset'), findsOneWidget);
    // The order-history tile still shows the surviving order.
    expect(find.text('1 order'), findsOneWidget);

    // Flush the snackbar timer before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('settings gear on the products screen opens the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final productsCubit = await loadProducts();
    addTearDown(productsCubit.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider.value(value: productsCubit),
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => WishlistCubit()),
          BlocProvider(create: (_) => OrdersCubit()),
          BlocProvider(create: (_) => SettingsCubit()),
        ],
        // The gear button navigates through the app router, so the harness
        // must host the real GoRouter (not a bare MaterialApp).
        child: MaterialApp.router(
          routerConfig: createAppRouter(),
          theme: buildShopTheme(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
  });

  testWidgets('order history tile shows the count and opens the orders screen', (
    tester,
  ) async {
    useTallViewport(tester);
    final ordersCubit = OrdersCubit();
    ordersCubit.recordOrder(
      Order(
        orderNumber: 'SH-9',
        placedAt: DateTime(2026, 7, 1),
        items: const [CartItem(product: _product, quantity: 1)],
      ),
    );
    addTearDown(ordersCubit.close);

    await tester.pumpWidget(
      buildApp(
        themeCubit: ThemeCubit(),
        productsCubit: await loadProducts(),
        cartCubit: CartCubit(),
        ordersCubit: ordersCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 order'), findsOneWidget);
    await tester.tap(find.text('Order history'));
    await tester.pumpAndSettle();
    expect(find.byType(OrdersScreen), findsOneWidget);
  });
}
