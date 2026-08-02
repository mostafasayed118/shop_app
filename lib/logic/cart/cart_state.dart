import 'package:equatable/equatable.dart';

import '../../data/models/cart_item.dart';

/// Immutable snapshot of the cart. Counts and totals are derived getters so
/// they can never drift out of sync with the item list.
class CartState extends Equatable {
  const CartState({this.items = const []});

  final List<CartItem> items;

  /// Total number of units across all items (used for the app-bar badge).
  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Live cart total across all items.
  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.total);

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items];
}
