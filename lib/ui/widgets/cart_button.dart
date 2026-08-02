import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../logic/cart/cart_cubit.dart';
import '../../logic/cart/cart_state.dart';

/// App-bar cart icon with a live item-count badge.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      // Rebuild only when the badge count actually changes.
      buildWhen: (previous, current) =>
          previous.itemsCount != current.itemsCount,
      builder: (context, state) {
        return IconButton(
          onPressed: () => context.push('/cart'),
          tooltip: 'Cart',
          icon: Badge(
            isLabelVisible: state.itemsCount > 0,
            label: Text('${state.itemsCount}'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        );
      },
    );
  }
}
