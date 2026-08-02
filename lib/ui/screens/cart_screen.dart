import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/strings.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/order.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/orders/orders_cubit.dart';
import '../../logic/cart/cart_state.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/owned_snack_bar.dart';
import '../widgets/price_text.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/status_view.dart';
import 'checkout_success_screen.dart';
import '../widgets/surface_card.dart';

/// Shopping cart: item lines with quantity steppers, live total, checkout.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with OwnedSnackBar<CartScreen> {
  void _clearCart() {
    context.read<CartCubit>().clear();
    showOwnedToast('Cart cleared');
  }

  void _removeItem(CartItem item) {
    context.read<CartCubit>().removeProduct(item.product.id);
    showOwnedToast('${item.product.name} removed from cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            buildWhen: (previous, current) =>
                previous.isEmpty != current.isEmpty,
            builder: (context, state) => IconButton(
              onPressed: state.isEmpty ? null : () => _clearCart(),
              tooltip: 'Clear cart',
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.isEmpty) {
            return const StatusView(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Add a few products before checking out.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _CartItemTile(
                item: item,
                onRemove: () => _removeItem(item),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        buildWhen: (previous, current) =>
            previous.totalPrice != current.totalPrice ||
            previous.isEmpty != current.isEmpty,
        builder: (context, state) {
          if (state.isEmpty) return const SizedBox.shrink();
          return _CheckoutBar(
            total: state.totalPrice,
            itemCount: state.itemsCount,
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.onRemove});

  final CartItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<CartCubit>();
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.product.imageAsset,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                PriceText(
                  item.product.price,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    QuantitySelector(
                      quantity: item.quantity,
                      min: 1,
                      onIncrement: () =>
                          cubit.incrementQuantity(item.product.id),
                      onDecrement: () =>
                          cubit.decrementQuantity(item.product.id),
                    ),
                    const Spacer(),
                    PriceText(
                      item.total,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.total, required this.itemCount});

  final double total;
  final int itemCount;

  // Requires [OrdersCubit] in scope (provided by the app) to record the
  // completed order; nothing in the cart screen's own build reads it, so the
  // dependency only surfaces here on the checkout tap.
  void _checkout(BuildContext context) {
    final cubit = context.read<CartCubit>();
    // Snapshot the order before clearing the cart — the success screen and
    // the order history can't read it back from the (now empty) cart, so the
    // full item list rides along. pushReplacement swaps the cart for the
    // confirmation.
    final order = Order.generate(items: List<CartItem>.of(cubit.state.items));
    cubit.clear();
    context.read<OrdersCubit>().recordOrder(order);
    context.pushReplacement(
      '/checkout-success',
      extra: CheckoutSuccessArgs(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BottomActionBar(
      above: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              PriceText(
                total,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${pluralize(itemCount, 'item')} \u00b7 Free delivery',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      button: FilledButton.icon(
        onPressed: () => _checkout(context),
        icon: const Icon(Icons.lock_outline),
        label: const Text('Checkout'),
      ),
    );
  }
}
