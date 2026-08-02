import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/product.dart';
import '../../logic/wishlist/wishlist_cubit.dart';
import '../../logic/wishlist/wishlist_state.dart';

/// Heart toggle for [product]. Filled when wishlisted, outlined otherwise;
/// tapping flips it via [WishlistCubit].
///
/// With [tonal] (default) it renders as the translucent compact chip used over
/// product-card photos; with `tonal: false` it becomes a plain app-bar icon
/// (for the detail screen), tinted only when saved.
///
/// Rebuilds only when this product's membership actually changes, so toggling
/// one heart doesn't rebuild every heart on screen.
class WishlistHeartButton extends StatelessWidget {
  const WishlistHeartButton({super.key, required this.product, this.tonal = true});

  final Product product;

  /// Overlay-chip styling (translucent backing, compact size) vs. a plain
  /// app-bar icon.
  final bool tonal;

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
          // The tonal chip gets a translucent surface backing so it reads over
          // a photo; the app-bar heart is a plain icon tinted when saved.
          style: tonal
              ? IconButton.styleFrom(
                  backgroundColor: scheme.surface.withValues(alpha: 0.92),
                  foregroundColor: saved
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                )
              : null,
          color: tonal ? null : (saved ? scheme.primary : null),
          visualDensity: tonal ? VisualDensity.compact : null,
          iconSize: tonal ? 20 : null,
          icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
        );
      },
    );
  }
}
