import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/product_repository.dart';
import 'package:e_commerce/data/repositories/wishlist_repository.dart';
import 'package:e_commerce/logic/cart/cart_cubit.dart';
import 'package:e_commerce/logic/products/products_cubit.dart';
import 'package:e_commerce/logic/theme/theme_cubit.dart';
import 'package:e_commerce/logic/wishlist/wishlist_cubit.dart';
import 'package:e_commerce/ui/router/app_router.dart';
import 'package:e_commerce/ui/screens/product_detail_screen.dart';
import 'package:e_commerce/ui/screens/wishlist_screen.dart';
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

const _headphones = Product(
  id: '1',
  name: 'Aurora Wireless Headphones',
  description: 'Over-ear headphones.',
  price: 249.99,
  imageAsset: 'assets/images/product_1.png',
  category: 'Audio',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProductsCubit> loadProducts() async {
    final cubit = ProductsCubit(_InstantRepository());
    await cubit.loadProducts();
    return cubit;
  }

  /// Hosts the real router over all four cubits, booting at [initialLocation]
  /// (screens like the wishlist navigate through GoRouter, so a bare
  /// MaterialApp would fail to resolve `context.push`).
  Widget buildApp(
    ProductsCubit productsCubit, {
    WishlistCubit? wishlistCubit,
    String initialLocation = '/',
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: productsCubit),
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider.value(value: wishlistCubit ?? WishlistCubit()),
      ],
      child: MaterialApp.router(
        routerConfig: createAppRouter(initialLocation: initialLocation),
        theme: buildShopTheme(),
      ),
    );
  }

  testWidgets('the card heart toggles the wishlist and the app-bar badge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final wishlistCubit = WishlistCubit();
    final productsCubit = await loadProducts();
    addTearDown(wishlistCubit.close);
    addTearDown(productsCubit.close);

    await tester.pumpWidget(
      buildApp(productsCubit, wishlistCubit: wishlistCubit),
    );
    await tester.pumpAndSettle();

    // Nothing saved yet: hearts are outlined, badge hidden.
    expect(find.byTooltip('Add to wishlist'), findsWidgets);
    expect(find.byTooltip('Remove from wishlist'), findsNothing);

    // Tapping the heart must NOT open the product details.
    await tester.tap(find.byTooltip('Add to wishlist').first);
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsNothing);

    // The first card is now saved: its heart is filled, the badge shows 1.
    expect(wishlistCubit.state.products, const [_headphones]);
    expect(find.byTooltip('Remove from wishlist'), findsOneWidget);
    expect(find.text('1'), findsWidgets);

    // Toggle back: the wishlist empties and the badge disappears.
    await tester.tap(find.byTooltip('Remove from wishlist'));
    await tester.pumpAndSettle();
    expect(wishlistCubit.state.isEmpty, isTrue);
    expect(find.byTooltip('Add to wishlist'), findsWidgets);
  });

  testWidgets('the detail screen heart favorites the product', (tester) async {
    final wishlistCubit = WishlistCubit();
    final productsCubit = await loadProducts();
    addTearDown(wishlistCubit.close);
    addTearDown(productsCubit.close);

    // Boot straight into a deep link so the detail screen is showing.
    await tester.pumpWidget(
      buildApp(
        productsCubit,
        wishlistCubit: wishlistCubit,
        initialLocation: '/product/1',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.byTooltip('Add to wishlist'), findsOneWidget);

    // Favoriting from the detail screen lands in the wishlist cubit and the
    // app-bar heart flips to its filled glyph.
    await tester.tap(find.byTooltip('Add to wishlist'));
    await tester.pumpAndSettle();
    expect(wishlistCubit.state.products, const [_headphones]);
    expect(find.byTooltip('Remove from wishlist'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);

    // And un-favoriting works too.
    await tester.tap(find.byTooltip('Remove from wishlist'));
    await tester.pumpAndSettle();
    expect(wishlistCubit.state.isEmpty, isTrue);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('the app-bar heart opens the wishlist screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final productsCubit = await loadProducts();
    addTearDown(productsCubit.close);

    await tester.pumpWidget(buildApp(productsCubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Wishlist'));
    await tester.pumpAndSettle();
    expect(find.byType(WishlistScreen), findsOneWidget);
  });

  testWidgets('wishlist screen shows an empty state when nothing is saved', (
    tester,
  ) async {
    final productsCubit = await loadProducts();
    addTearDown(productsCubit.close);

    await tester.pumpWidget(
      buildApp(productsCubit, initialLocation: '/wishlist'),
    );
    await tester.pumpAndSettle();

    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('wishlist screen lists saved products, removes with a toast, '
      'and opens details', (tester) async {
    final wishlistCubit = WishlistCubit();
    wishlistCubit.toggle(_headphones);
    final productsCubit = await loadProducts();
    addTearDown(wishlistCubit.close);
    addTearDown(productsCubit.close);

    await tester.pumpWidget(
      buildApp(
        productsCubit,
        wishlistCubit: wishlistCubit,
        initialLocation: '/wishlist',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);

    // The tile opens the product detail screen.
    await tester.tap(find.text('Aurora Wireless Headphones'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Removing un-saves it and confirms with a toast.
    await tester.tap(find.byTooltip('Remove from wishlist'));
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsOneWidget);
    expect(
      find.textContaining('removed from wishlist'),
      findsOneWidget,
    );

    // Flush the snackbar timer before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('the wishlist survives a restart via the persistence store', (
    tester,
  ) async {
    final productsCubit = await loadProducts();
    addTearDown(productsCubit.close);

    // Session 1: save a favorite through the real repository.
    final sessionOne = WishlistCubit(WishlistRepository());
    await tester.pumpWidget(
      buildApp(productsCubit, wishlistCubit: sessionOne),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to wishlist').first);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);

    // "Restart": a brand-new cubit over the same store brings the badge back.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final sessionTwo = WishlistCubit(WishlistRepository());
    await tester.pumpWidget(buildApp(productsCubit, wishlistCubit: sessionTwo));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);
    expect(sessionTwo.state.products, const [_headphones]);

    await sessionOne.close();
    await sessionTwo.close();
  });
}
