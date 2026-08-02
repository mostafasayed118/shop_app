import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/strings.dart';
import '../../data/models/order.dart';
import '../../logic/cart/cart_cubit.dart';

/// Reorder behavior shared by the order history card and the order detail
/// screen: re-adds the order's snapshot items to the cart and toasts the
/// count. Hosts are [OwnedSnackBar] states exposing the order in question —
/// [context], [order] and [showOwnedToast] all come from the host state.
///
/// The snapshots embed the full product, so a reorder works even if the
/// catalogue has since changed or the product is no longer listed.
mixin OrderReorder {
  BuildContext get context;

  /// The order whose items are re-added to the cart.
  Order get order;

  /// Provided by the [OwnedSnackBar] mixin applied alongside this one.
  void showOwnedToast(String message);

  void reorder() {
    context.read<CartCubit>().addItems(order.items);
    showOwnedToast('${pluralize(order.itemCount, 'item')} added to cart');
  }
}
