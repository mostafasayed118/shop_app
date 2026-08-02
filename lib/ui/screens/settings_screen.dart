import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/strings.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/cart/cart_state.dart';
import '../../logic/orders/orders_cubit.dart';
import '../../logic/orders/orders_state.dart';
import '../../logic/products/products_cubit.dart';
import '../../logic/products/products_state.dart';
import '../../logic/theme/theme_cubit.dart';
import '../../logic/wishlist/wishlist_cubit.dart';
import '../widgets/owned_snack_bar.dart';
import '../widgets/surface_card.dart';

/// App settings: appearance (theme mode), catalogue defaults, data actions
/// and an about blurb.
///
/// Deliberately a thin reactive view over the existing cubits — theme, cart
/// and catalogue preferences already own their state and persistence, so this
/// screen never duplicates that logic; it just renders it and dispatches
/// through the owning cubit. Destructive actions are confirmed first.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with OwnedSnackBar<SettingsScreen> {
  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _clearCart() async {
    final items = context.read<CartCubit>().state.itemsCount;
    final confirmed = await _confirm(
      title: 'Clear cart?',
      message: 'Remove all ${pluralize(items, 'item')} from your cart?',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    context.read<CartCubit>().clear();
    showOwnedToast('Cart cleared');
  }

  Future<void> _resetFilters() async {
    final confirmed = await _confirm(
      title: 'Reset saved filters?',
      message:
          'Your search text, selected category and sort choice will return '
          'to their defaults.',
      confirmLabel: 'Reset',
    );
    if (!confirmed || !mounted) return;
    context.read<ProductsCubit>().resetCataloguePreferences();
    showOwnedToast('Catalogue filters reset');
  }

  Future<void> _resetAllData() async {
    final confirmed = await _confirm(
      title: 'Reset all data?',
      message:
          'This clears your cart and wishlist, resets saved catalogue filters '
          'and returns to the system theme. Your order history is kept. '
          'It cannot be undone.',
      confirmLabel: 'Reset all',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    context.read<CartCubit>().clear();
    context.read<WishlistCubit>().clear();
    context.read<ProductsCubit>().resetCataloguePreferences();
    context.read<ThemeCubit>().setThemeMode(ThemeMode.system);
    showOwnedToast('All data reset');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Appearance'),
          _ThemeCard(),
          const SizedBox(height: 24),
          const _SectionHeader('Catalogue'),
          _CatalogueCard(onResetFilters: _resetFilters),
          const SizedBox(height: 24),
          const _SectionHeader('Account'),
          const _OrdersCard(),
          const SizedBox(height: 24),
          const _SectionHeader('Data'),
          _DataCard(onClearCart: _clearCart, onResetAll: _resetAllData),
          const SizedBox(height: 24),
          const _SectionHeader('About'),
          const _AboutCard(),
        ],
      ),
    );
  }
}

/// Uppercase, primary-colored section label — the same treatment the product
/// detail screen uses for the category eyebrow.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// System / Light / Dark selector, backed by the shared [ThemeCubit] so the
/// app-bar toggle and this screen always agree.
class _ThemeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => SegmentedButton<ThemeMode>(
          // Fill the card edge to edge instead of hugging the content.
          expandedInsets: EdgeInsets.zero,
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Dark'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) =>
              context.read<ThemeCubit>().setThemeMode(selection.first),
        ),
      ),
    );
  }
}

/// Restores the saved search / category / sort configuration to defaults.
class _CatalogueCard extends StatelessWidget {
  const _CatalogueCard({required this.onResetFilters});

  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: BlocBuilder<ProductsCubit, ProductsState>(
        // Only the loaded state carries the current filter configuration.
        buildWhen: (previous, current) =>
            previous is ProductsLoaded || current is ProductsLoaded,
        builder: (context, state) {
          final hasCustomFilters = state is ProductsLoaded &&
              (state.query.isNotEmpty ||
                  state.selectedCategory != null ||
                  state.sortField != SortField.featured ||
                  state.sortDirection != SortDirection.ascending);
          return ListTile(
            enabled: hasCustomFilters,
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset saved filters'),
            subtitle: const Text('Search, category and sort return to defaults'),
            onTap: hasCustomFilters ? onResetFilters : null,
          );
        },
      ),
    );
  }
}

/// Navigation into the order history, with a live count of recorded orders.
class _OrdersCard extends StatelessWidget {
  const _OrdersCard();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) => ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Order history'),
          subtitle: Text(
            state.isEmpty
                ? 'No orders yet'
                : pluralize(state.orders.length, 'order'),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/orders'),
        ),
      ),
    );
  }
}

/// Cart and app-wide data actions. The clear-cart tile reflects the live cart
/// count (and is disabled when the cart is empty).
class _DataCard extends StatelessWidget {
  const _DataCard({required this.onClearCart, required this.onResetAll});

  final VoidCallback onClearCart;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              enabled: !state.isEmpty,
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Clear cart'),
              subtitle: Text(
                state.isEmpty
                    ? 'Cart is empty'
                    : '${pluralize(state.itemsCount, 'item')} in cart',
              ),
              onTap: state.isEmpty ? null : onClearCart,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: const Text('Reset all data'),
              subtitle: const Text(
                'Clears cart, wishlist, saved filters and theme',
              ),
              onTap: onResetAll,
            ),
          ],
        ),
      ),
    );
  }
}

/// Static app blurb. The version mirrors `pubspec.yaml`; keeping it in sync
/// by hand is fine for a demo (no package_info dependency needed).
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shoply',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Offline-first e-commerce demo — no backend.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: muted),
              const SizedBox(width: 8),
              Text(
                'Version 1.0.0',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.code, size: 18, color: muted),
              const SizedBox(width: 8),
              Text(
                'Made with Flutter',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
