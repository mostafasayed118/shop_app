import 'package:e_commerce/data/models/cart_item.dart';
import 'package:e_commerce/data/models/order.dart';
import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/data/repositories/orders_repository.dart';
import 'package:e_commerce/ui/router/app_router.dart';
import 'package:e_commerce/logic/orders/orders_cubit.dart';
import 'package:e_commerce/main.dart';
import 'package:e_commerce/ui/screens/checkout_success_screen.dart';
import 'package:e_commerce/ui/screens/order_detail_screen.dart';
import 'package:e_commerce/ui/screens/orders_screen.dart';
import 'package:e_commerce/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Widget buildApp(OrdersCubit ordersCubit) {
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: ordersCubit)],
      // The order cards navigate through the app router, so the harness must
      // host a real GoRouter booting at the orders screen.
      child: MaterialApp.router(
        routerConfig: createAppRouter(initialLocation: '/orders'),
        theme: buildShopTheme(),
      ),
    );
  }

  testWidgets('order history shows an empty state when nothing was ordered', (
    tester,
  ) async {
    final ordersCubit = OrdersCubit();
    addTearDown(ordersCubit.close);

    await tester.pumpWidget(buildApp(ordersCubit));
    await tester.pumpAndSettle();

    expect(find.text('No orders yet'), findsOneWidget);
  });

  testWidgets('order history lists recorded orders with number, date and total', (
    tester,
  ) async {
    final ordersCubit = OrdersCubit();
    ordersCubit.recordOrder(
      Order(
        orderNumber: 'SH-123456',
        placedAt: DateTime(2026, 7, 1),
        items: const [CartItem(product: _headphones, quantity: 2)],
      ),
    );
    addTearDown(ordersCubit.close);

    await tester.pumpWidget(buildApp(ordersCubit));
    await tester.pumpAndSettle();

    expect(find.text('SH-123456'), findsOneWidget);
    expect(find.text('01/07/2026'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);
    expect(find.text(r'$499.98'), findsOneWidget);
    expect(find.text('Aurora Wireless Headphones ×2'), findsOneWidget);
  });

  testWidgets('tapping an order card opens its detail with line items', (
    tester,
  ) async {
    final ordersCubit = OrdersCubit();
    ordersCubit.recordOrder(
      Order(
        orderNumber: 'SH-123456',
        placedAt: DateTime(2026, 7, 1),
        items: const [CartItem(product: _headphones, quantity: 2)],
      ),
    );
    addTearDown(ordersCubit.close);

    await tester.pumpWidget(buildApp(ordersCubit));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SH-123456'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(find.text('Aurora Wireless Headphones'), findsOneWidget);
    expect(find.text(r'2 × $249.99'), findsOneWidget);
    // The header combines the date and item count in a single Text.
    expect(find.text('01/07/2026 · 2 items'), findsOneWidget);
    // For a single line the line total and grand total are the same amount.
    expect(find.text(r'$499.98'), findsWidgets);
  });

  testWidgets('a completed checkout lands in order history', (tester) async {
    // A realistic phone viewport so the grid, cart and checkout are usable.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ShopApp());
    await tester.pump(const Duration(milliseconds: 800)); // repo delay
    await tester.pumpAndSettle();

    // Add a product, then check out.
    await tester.tap(find.text('Aurora Wireless Headphones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    // The confirmation shows the recorded order number.
    expect(find.byType(CheckoutSuccessScreen), findsOneWidget);
    expect(find.text('Order confirmed!'), findsOneWidget);
    expect(find.textContaining('Order #SH-'), findsOneWidget);

    // The success screen links straight into the history.
    await tester.tap(find.text('View order history'));
    await tester.pumpAndSettle();
    expect(find.byType(OrdersScreen), findsOneWidget);
    expect(find.textContaining('SH-'), findsOneWidget);
    expect(find.text('Aurora Wireless Headphones ×1'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);

    // Flush any pending snackbar timers before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a fresh app restores the saved order history', (tester) async {
    // Session 1: record an order through the real repository.
    final sessionOne = OrdersCubit(OrdersRepository());
    sessionOne.recordOrder(
      Order(
        orderNumber: 'SH-42',
        placedAt: DateTime(2026, 7, 2),
        items: const [CartItem(product: _headphones, quantity: 1)],
      ),
    );
    await tester.pumpWidget(buildApp(sessionOne));
    await tester.pumpAndSettle();
    expect(find.text('SH-42'), findsOneWidget);

    // "Restart": a brand-new cubit over the same store restores the order.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final sessionTwo = OrdersCubit(OrdersRepository());
    await tester.pumpWidget(buildApp(sessionTwo));
    await tester.pumpAndSettle();
    expect(find.text('SH-42'), findsOneWidget);

    await sessionOne.close();
    await sessionTwo.close();
  });
}
