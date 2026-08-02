import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/product.dart';
import '../../logic/products/products_cubit.dart';
import '../../logic/products/products_state.dart';
import '../widgets/cart_button.dart';
import '../widgets/category_chips.dart';
import '../widgets/owned_snack_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/product_grid.dart';
import '../widgets/search_field.dart';
import '../widgets/settings_button.dart';
import '../widgets/skeleton_grid.dart';
import '../widgets/sort_control.dart';
import '../widgets/status_view.dart';
import '../widgets/theme_mode_button.dart';
import '../widgets/wishlist_button.dart';

/// Catalogue home: search + category filters + sorting over a responsive grid,
/// with explicit loading / error / empty / no-results states.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  /// Responsive: 2 columns on phones, 4 on wide screens (tablets/desktop).
  static int _columnCount(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900 ? 4 : 2;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with OwnedSnackBar<ProductsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoply'),
        actions: const [
          WishlistButton(),
          SettingsButton(),
          ThemeModeButton(),
          CartButton(),
        ],
      ),
      body: BlocListener<ProductsCubit, ProductsState>(
        // A failed refresh keeps the grid on screen; surface it as a transient
        // snackbar instead of swapping in the full-screen error view. Also
        // react to the recovery transition (refreshFailed true → false) so a
        // stale message is dismissed once fresh data lands.
        listenWhen: (previous, current) =>
            current is ProductsLoaded &&
            (current.refreshFailed ||
                (previous is ProductsLoaded && previous.refreshFailed)),
        listener: (context, state) {
          if (state is ProductsLoaded && state.refreshFailed) {
            showOwnedToast(
              'Couldn\u2019t refresh \u2014 showing the last loaded products.',
            );
          } else {
            // A refresh recovered (or the flag was cleared): dismiss the stale
            // "couldn't refresh" message — and only that one.
            hideOwnedSnackBar();
          }
        },
        child: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            return switch (state) {
              ProductsInitial() || ProductsLoading() => SkeletonGrid(
                crossAxisCount: ProductsScreen._columnCount(context),
              ),
              ProductsError(:final message) => StatusView(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load products',
                message: message,
                action: FilledButton.icon(
                  onPressed: () => context.read<ProductsCubit>().loadProducts(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ),
              ProductsLoaded() => _CatalogueView(state: state),
            };
          },
        ),
      ),
    );
  }
}

/// The loaded catalogue: search bar + category chips + sort above the grid.
class _CatalogueView extends StatelessWidget {
  const _CatalogueView({required this.state});

  final ProductsLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.products.isEmpty) {
      return const StatusView(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        message: 'Check back soon \u2014 new items are on the way.',
      );
    }

    final visible = state.sortedProducts;
    final categories = state.products.map((p) => p.category).toSet().toList()
      ..sort();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SearchField(
                query: state.query,
                hintText: 'Search products',
                onChanged: (value) =>
                    context.read<ProductsCubit>().updateQuery(value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 16, left: 4),
              child: SortControl(
                field: state.sortField,
                direction: state.sortDirection,
                onSelected: (field, direction) =>
                    context.read<ProductsCubit>().setSort(field, direction),
              ),
            ),
          ],
        ),
        CategoryChips(
          categories: categories,
          selectedCategory: state.selectedCategory,
          onSelected: (category) =>
              context.read<ProductsCubit>().selectCategory(category),
        ),
        Expanded(
          child: visible.isEmpty
              ? _buildNoResults(context)
              : _buildGrid(context, visible),
        ),
      ],
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return StatusView(
      icon: Icons.search_off,
      title: 'No matches found',
      message: 'Try a different search term or category.',
      action: OutlinedButton.icon(
        onPressed: () {
          context.read<ProductsCubit>()
            ..updateQuery('')
            ..selectCategory(null);
        },
        icon: const Icon(Icons.filter_alt_off),
        label: const Text('Clear filters'),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Product> products) {
    return RefreshIndicator(
      onRefresh: () => context.read<ProductsCubit>().loadProducts(),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: kProductGridPadding,
        gridDelegate: productGridDelegate(ProductsScreen._columnCount(context)),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}
