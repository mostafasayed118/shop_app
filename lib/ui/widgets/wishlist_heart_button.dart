import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/product.dart';
import '../../logic/wishlist/wishlist_cubit.dart';
import '../../logic/wishlist/wishlist_state.dart';

/// Heart toggle for [product], used over the product-card image. Filled when
/// wishlisted, outlined otherwise; tapping flips it via [WishlistCubit].
///
/// Rebuilds only when this product's membership actually changes, so toggling
/// one card doesn't rebuild every heart on screen.
class WishlistHeartButton extends StatelessWidget {
  const WishlistHeartButton({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, WishlistState>(
      buildWhen: (previous, current) =>
          previous.contains(product.id) != current.contains(product.id),
      builder: (context, state) {
        final saved = state.contains(product.id);
        final scheme = Theme.of(context).colorScheme;
        return IconButton(
          onPressed: () => context.read<WishlistCubit>().toggle(product),
          tooltip: saved ? 'Remove from wishlist' : 'Add to wishlist',
          // A translucent surface chip so the heart reads over the photo.
          style: IconButton.styleFrom(
            backgroundColor: scheme.surface.withValues(alpha: 0.92),
            foregroundColor: saved ? scheme.primary : scheme.onSurfaceVariant,
          ),
          visualDensity: VisualDensity.compact,
          icon: Icon(saved ? Icons.favorite : Icons.favorite_border, size: 20),
        );
      },
    );
  }
}
