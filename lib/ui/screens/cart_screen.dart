import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/money.dart';
import '../../data/models/cart_item.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/cart/cart_state.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/status_view.dart';
import 'checkout_success_screen.dart';

/// Shopping cart: item lines with quantity steppers, live total, checkout.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            buildWhen: (previous, current) => previous.isEmpty != current.isEmpty,
            builder: (context, state) => IconButton(
              onPressed: state.isEmpty ? null : () => context.read<CartCubit>().clear(),
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
            itemBuilder: (context, index) =>
                _CartItemTile(item: state.items[index]),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        buildWhen: (previous, current) =>
            previous.totalPrice != current.totalPrice ||
            previous.isEmpty != current.isEmpty,
        builder: (context, state) {
          if (state.isEmpty) return const SizedBox.shrink();
          return _CheckoutBar(total: state.totalPrice, itemCount: state.itemsCount);
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<CartCubit>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
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
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPrice(item.product.price),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    QuantitySelector(
                      quantity: item.quantity,
                      min: 1,
                      onIncrement: () => cubit.incrementQuantity(item.product.id),
                      onDecrement: () => cubit.decrementQuantity(item.product.id),
                    ),
                    const Spacer(),
                    Text(
                      formatPrice(item.total),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () => cubit.removeProduct(item.product.id),
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

  void _checkout(BuildContext context) {
    final cubit = context.read<CartCubit>();
    // Snapshot the order before clearing the cart.
    final paidTotal = cubit.state.totalPrice;
    final paidItems = cubit.state.itemsCount;
    cubit.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            CheckoutSuccessScreen(total: paidTotal, itemCount: paidItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Total',
                style:
                    theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                formatPrice(total),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$itemCount item${itemCount == 1 ? '' : 's'} \u00b7 Free delivery',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _checkout(context),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}
