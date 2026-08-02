import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/product_repository.dart';
import 'package:e_commerce/logic/cart/cart_cubit.dart';
import 'package:e_commerce/logic/products/products_cubit.dart';
import 'package:e_commerce/logic/theme/theme_cubit.dart';
import 'package:e_commerce/logic/wishlist/wishlist_cubit.dart';
import 'package:e_commerce/main.dart';
import 'package:e_commerce/ui/router/app_router.dart';
import 'package:e_commerce/ui/screens/cart_screen.dart';
import 'package:e_commerce/ui/screens/not_found_screen.dart';
import 'package:e_commerce/ui/screens/product_detail_screen.dart';
import 'package:e_commerce/ui/screens/products_screen.dart';
import 'package:e_commerce/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository that resolves instantly (microtasks only, no timers).
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
  Widget buildApp(ProductsCubit productsCubit, {String initialLocation = '/'}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: productsCubit),
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider(create: (_) => WishlistCubit()),
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
