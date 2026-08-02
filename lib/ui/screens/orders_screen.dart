import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/strings.dart';
import '../../data/models/order.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/orders/orders_cubit.dart';
import '../../logic/orders/orders_state.dart';
import '../widgets/owned_snack_bar.dart';
import '../widgets/price_text.dart';
import '../widgets/status_view.dart';
import '../widgets/surface_card.dart';

/// Completed orders, most recent first. Each card summarizes the number,
/// date, lines and total, and offers a one-tap reorder; history is a demo
/// record, not a real fulfillment system.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order history')),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state.isEmpty) {
            return const StatusView(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Check out to see your orders here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _OrderCard(order: state.orders[index]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> with OwnedSnackBar<_OrderCard> {
  Order get order => widget.order;

  /// Re-adds the order's snapshot items to the cart. The snapshots are
  /// self-contained (they embed the full product), so a reorder works even if
  /// the catalogue has since changed or the product is no longer listed.
  void _reorder() {
    context.read<CartCubit>().addItems(order.items);
    showOwnedToast('${pluralize(order.itemCount, 'item')} added to cart');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final lines =
        order.items.map((item) => '${item.product.name} ×${item.quantity}');

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      // The full order rides along as `extra`; the route falls back to an
      // order-number lookup for deep links.
      onTap: () => context.push('/orders/${order.orderNumber}', extra: order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 20, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PriceText(
                order.total,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formatShortDate(order.placedAt),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(width: 8),
              Text(
                '·',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(width: 8),
              Text(
                pluralize(order.itemCount, 'item'),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              lines.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Its own gesture recognizer wins over the card's InkWell, so
              // tapping Reorder never opens the detail screen.
              TextButton.icon(
                onPressed: _reorder,
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Reorder'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
