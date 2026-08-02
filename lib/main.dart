import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'data/repositories/cart_repository.dart';
import 'data/repositories/catalogue_preferences_repository.dart';
import 'data/repositories/orders_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/theme_mode_repository.dart';
import 'data/repositories/wishlist_repository.dart';
import 'logic/cart/cart_cubit.dart';
import 'logic/orders/orders_cubit.dart';
import 'logic/products/products_cubit.dart';
import 'logic/settings/settings_cubit.dart';
import 'logic/theme/theme_cubit.dart';
import 'logic/wishlist/wishlist_cubit.dart';
import 'ui/router/app_router.dart';
import 'ui/theme/app_theme.dart';


void main() {
  runApp(const ShopApp());
}

/// Root widget: wires state management (MultiBlocProvider) and theming, and
/// hosts the [GoRouter] that owns all navigation.
class ShopApp extends StatefulWidget {
  const ShopApp({super.key});

  @override
  State<ShopApp> createState() => _ShopAppState();
}

class _ShopAppState extends State<ShopApp> {
  // One router per app instance, created exactly once: a fresh instance per
  // ShopApp keeps navigation state isolated (tests), and holding it in the
  // State (not rebuilding it) means theme changes don't reset the stack.
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Restores a previously saved theme override (default: system mode).
        BlocProvider(create: (_) => ThemeCubit(ThemeModeRepository())),
        // Kick off the catalogue load immediately so the grid is ready as
        // soon as the first frame settles.
        BlocProvider(
          create: (_) => ProductsCubit(
            ProductRepository(),
            CataloguePreferencesRepository(),
          )..loadProducts(),
        ),
        // The cart restores a previously saved cart on construction.
        BlocProvider(create: (_) => CartCubit(CartRepository())),
        // The wishlist restores saved favorites on construction.
        BlocProvider(create: (_) => WishlistCubit(WishlistRepository())),
        // Order history restores completed orders on construction.
        BlocProvider(create: (_) => OrdersCubit(OrdersRepository())),
        // Settings restore the saved display currency on construction.
        BlocProvider(create: (_) => SettingsCubit(SettingsRepository())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          title: 'Shoply',
          debugShowCheckedModeBanner: false,
          theme: buildShopTheme(),
          darkTheme: buildShopTheme(brightness: Brightness.dark),
          themeMode: themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
