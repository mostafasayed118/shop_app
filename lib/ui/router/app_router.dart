import 'package:go_router/go_router.dart';

import '../../data/models/product.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_success_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_resolver_screen.dart';
import '../screens/products_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/wishlist_screen.dart';

/// Builds a fresh [GoRouter] for the app. It's a function (not a top-level
/// singleton) so every `ShopApp` instance owns its own page stack — a shared
/// router would leak navigation state across app instances and tests.
///
/// [initialLocation] is exposed so tests can boot straight into a deep link.
GoRouter createAppRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    // Any route that matches nothing (e.g. a stale web deep link) lands here.
    errorBuilder: (context, state) =>
        NotFoundScreen(message: 'We couldn\u2019t find \u201c${state.uri}\u201d.'),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ProductsScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          // In-app navigation passes the full product via `extra` so the
          // detail screen never waits on a lookup. A deep link (web) has no
          // extra: the resolver waits for the catalogue to load rather than
          // failing while the initial load is still in flight.
          final extra = state.extra;
          if (extra is Product) return ProductDetailScreen(product: extra);
          final id = state.pathParameters['id'];
          if (id == null) {
            return NotFoundScreen(message: 'That product isn\u2019t available.');
          }
          return ProductResolverScreen(productId: id);
        },
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/checkout-success',
        builder: (context, state) {
          final args = state.extra;
          if (args is! CheckoutSuccessArgs) {
            // A direct deep link has no order to confirm.
            return NotFoundScreen(message: 'No order to confirm here.');
          }
          return CheckoutSuccessScreen(order: args.order);
        },
      ),
    ],
  );
}
