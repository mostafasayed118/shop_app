import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/money.dart';
import '../../core/utils/strings.dart';
import '../../data/models/order.dart';
import '../widgets/circle_icon.dart';

/// Route input contract for the checkout-success route. The cart is cleared
/// *before* navigating, so the order can't be read back from the cart — it
/// travels along as [GoRouterState.extra]. Lives here (with its consumer) so
/// the router and the cart screen don't form an import cycle.
class CheckoutSuccessArgs {
  const CheckoutSuccessArgs({required this.order});

  final Order order;
}

/// Mock order confirmation — no real payment is processed. Shows the order
/// that was just recorded (and links to the full history).
class CheckoutSuccessScreen extends StatelessWidget {
  const CheckoutSuccessScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order placed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleIcon(
                icon: Icons.check_rounded,
                size: 104,
                iconSize: 56,
                backgroundColor: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.6,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order confirmed!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${order.orderNumber}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${pluralize(order.itemCount, 'item')} · '
                '${formatPrice(order.total)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This is a demo checkout — no payment was processed.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // Reset to the catalogue whatever the stack depth; the
                  // products cubit lives above the navigator, so the grid
                  // state is preserved.
                  onPressed: () => context.go('/'),
                  child: const Text('Continue shopping'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.push('/orders'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View order history'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
