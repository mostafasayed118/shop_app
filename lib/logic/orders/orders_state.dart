import 'package:equatable/equatable.dart';

import '../../data/models/order.dart';

/// Immutable snapshot of the order history.
class OrdersState extends Equatable {
  const OrdersState({this.orders = const []});

  final List<Order> orders;

  bool get isEmpty => orders.isEmpty;

  @override
  List<Object?> get props => [orders];
}
