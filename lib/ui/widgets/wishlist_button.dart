import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../logic/wishlist/wishlist_cubit.dart';
import '../../logic/wishlist/wishlist_state.dart';

/// App-bar wishlist icon with a live count badge.
class WishlistButton extends StatelessWidget {
  const WishlistButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, WishlistState>(
      // Rebuild only when the badge count actually changes.
      buildWhen: (previous, current) =>
          previous.products.length != current.products.length,
      builder: (context, state) {
        return IconButton(
          onPressed: () => context.push('/wishlist'),
          tooltip: 'Wishlist',
          icon: Badge(
            isLabelVisible: state.products.isNotEmpty,
            label: Text('${state.products.length}'),
            child: const Icon(Icons.favorite_border),
          ),
        );
      },
    );
  }
}
