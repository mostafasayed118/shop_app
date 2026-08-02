import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/repositories/cart_repository.dart';
import 'data/repositories/catalogue_preferences_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/theme_mode_repository.dart';
import 'logic/cart/cart_cubit.dart';
import 'logic/products/products_cubit.dart';
import 'logic/theme/theme_cubit.dart';
import 'ui/screens/products_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const ShopApp());
}

/// Root widget: wires state management (MultiBlocProvider) and theming.
class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

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
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp(
          title: 'Shoply',
          debugShowCheckedModeBanner: false,
          theme: buildShopTheme(),
          darkTheme: buildShopTheme(brightness: Brightness.dark),
          themeMode: themeMode,
          home: const ProductsScreen(),
        ),
      ),
    );
  }
}
