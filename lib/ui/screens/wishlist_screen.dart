import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/product.dart';
import '../../logic/wishlist/wishlist_cubit.dart';
import '../../logic/wishlist/wishlist_state.dart';
import '../widgets/owned_snack_bar.dart';
import '../widgets/price_text.dart';
import '../widgets/status_view.dart';
import '../widgets/surface_card.dart';

/// Saved products, each tile opening its detail screen; the heart un-saves.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with OwnedSnackBar<WishlistScreen> {
  void _remove(Product product) {
    context.read<WishlistCubit>().remove(product.id);
    showOwnedToast('${product.name} removed from wishlist');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state.isEmpty) {
            return const StatusView(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              message: 'Tap the heart on any product to save it here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = state.products[index];
              return _WishlistTile(
                product: product,
                onRemove: () => _remove(product),
              );
            },
          );
        },
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({required this.product, required this.onRemove});

  final Product product;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: () => context.push('/product/${product.id}', extra: product),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              product.imageAsset,
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
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                PriceText(
                  product.price,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Always filled here (the tile is only built for saved products);
          // un-saving routes through the screen so it can confirm with a
          // toast. This deliberately bypasses the shared card heart, whose
          // silent toggle is right for the grid but not for a management view.
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove from wishlist',
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            icon: const Icon(Icons.favorite),
          ),
        ],
      ),
    );
  }
}
