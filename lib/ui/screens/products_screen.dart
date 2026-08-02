import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/product.dart';
import '../../logic/products/products_cubit.dart';
import '../../logic/products/products_state.dart';
import '../widgets/cart_button.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton_grid.dart';
import '../widgets/status_view.dart';

/// Catalogue home: search + category filters + sorting over a responsive grid,
/// with explicit loading / error / empty / no-results states.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  static const _gridPadding = EdgeInsets.all(16);

  /// Responsive: 2 columns on phones, 4 on wide screens (tablets/desktop).
  static int _columnCount(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900 ? 4 : 2;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  /// The currently-visible "couldn't refresh" snackbar, so a recovery dismisses
  /// exactly that one without touching unrelated toasts (e.g. "added to cart").
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _refreshSnackBar;

  void _showRefreshSnackBar() {
    // Replace a previously shown refresh message; other toasts are left alone
    // (they queue behind ours if still on screen).
    _refreshSnackBar?.close();
    final controller = ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Couldn\u2019t refresh \u2014 showing the last loaded products.',
        ),
      ),
    );
    _refreshSnackBar = controller;
    // Forget the reference once it's gone (auto-dismiss timer or close()), so
    // a later recovery never touches a snackbar that is no longer showing.
    controller.closed.whenComplete(() {
      if (_refreshSnackBar == controller) _refreshSnackBar = null;
    });
  }

  void _hideRefreshSnackBar() => _refreshSnackBar?.close();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoply'),
        actions: const [CartButton()],
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
            _showRefreshSnackBar();
          } else {
            // A refresh recovered (or the flag was cleared): dismiss the stale
            // "couldn't refresh" message — and only that one.
            _hideRefreshSnackBar();
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ProductSearchBar(
                query: state.query,
                onChanged: (value) =>
                    context.read<ProductsCubit>().updateQuery(value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 16, left: 4),
              child: _SortControl(
                field: state.sortField,
                direction: state.sortDirection,
                onSelected: (field, direction) =>
                    context.read<ProductsCubit>().setSort(field, direction),
              ),
            ),
          ],
        ),
        _CategoryChips(
          products: state.products,
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
        padding: ProductsScreen._gridPadding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ProductsScreen._columnCount(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          // Square image + fixed text block underneath.
          childAspectRatio: 0.6,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}

/// Search field that stays in sync with [ProductsLoaded.query].
class _ProductSearchBar extends StatefulWidget {
  const _ProductSearchBar({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<_ProductSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(_ProductSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when the state changes externally, e.g. the
    // "Clear filters" action resets the query.
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged(value);
    setState(() {}); // Refresh the clear (suffix) icon.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search products',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                  },
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrollable category chips derived from the catalogue.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.products,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<Product> products;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = products.map((p) => p.category).toSet().toList()..sort();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedCategory == null,
              showCheckmark: false,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: ChoiceChip(
                label: Text(category),
                selected: selectedCategory == category,
                showCheckmark: false,
                // Tapping the active chip returns to "All".
                onSelected: (_) =>
                    onSelected(selectedCategory == category ? null : category),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sort menu: featured (catalogue order) or price/name in either direction.
class _SortControl extends StatelessWidget {
  const _SortControl({
    required this.field,
    required this.direction,
    required this.onSelected,
  });

  final SortField field;
  final SortDirection direction;
  final void Function(SortField field, SortDirection direction) onSelected;

  static const _labels = <(SortField, SortDirection), String>{
    (SortField.featured, SortDirection.ascending): 'Featured',
    (SortField.price, SortDirection.ascending): 'Price: low to high',
    (SortField.price, SortDirection.descending): 'Price: high to low',
    (SortField.name, SortDirection.ascending): 'Name: A to Z',
    (SortField.name, SortDirection.descending): 'Name: Z to A',
  };

  @override
  Widget build(BuildContext context) {
    final active = field != SortField.featured;
    final color = Theme.of(context).colorScheme;
    return PopupMenuButton<(SortField, SortDirection)>(
      tooltip: 'Sort products',
      icon: Icon(Icons.swap_vert, color: active ? color.primary : null),
      onSelected: (option) => onSelected(option.$1, option.$2),
      itemBuilder: (context) => [
        for (final entry in _labels.entries)
          CheckedPopupMenuItem<(SortField, SortDirection)>(
            value: entry.key,
            checked: entry.key == (field, direction),
            child: Text(entry.value),
          ),
      ],
    );
  }
}
