import 'package:equatable/equatable.dart';

import '../../data/models/order.dart';

/// Immutable snapshot of the order history.
class OrdersState extends Equatable {
  const OrdersState({this.orders = const [], this.restored = true});

  final List<Order> orders;

  /// Whether the initial restore from the store has finished. `false` only
  /// while a repository-backed cubit is still loading its saved history, so a
  /// deep link can distinguish "still restoring" from "restored but empty"
  /// instead of wrongly showing not-found.
  final bool restored;

  bool get isEmpty => orders.isEmpty;

  @override
  List<Object?> get props => [orders, restored];
}
