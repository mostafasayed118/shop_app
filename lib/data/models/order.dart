import 'dart:math';

import 'package:equatable/equatable.dart';

import 'cart_item.dart';

/// A completed order: a snapshot of what was bought when checkout ran. Totals
/// are derived from [items] so they can never drift from the lines. Immutable
/// and value-comparable via [Equatable].
class Order extends Equatable {
  const Order({
    required this.orderNumber,
    required this.placedAt,
    required this.items,
  });

  /// Creates an order for [items], minting a human-friendly order number and
  /// stamping the current time — the checkout flow's single entry point.
  factory Order.generate({required List<CartItem> items}) {
    return Order(
      orderNumber: 'SH-${100000 + Random().nextInt(900000)}',
      placedAt: DateTime.now(),
      items: items,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderNumber: json['orderNumber'] as String,
      placedAt: DateTime.parse(json['placedAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String orderNumber;
  final DateTime placedAt;
  final List<CartItem> items;

  /// Total paid across all lines.
  double get total => items.fold(0.0, (sum, item) => sum + item.total);

  /// Total number of units across all lines.
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() => {
    'orderNumber': orderNumber,
    'placedAt': placedAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
  };

  @override
  List<Object?> get props => [orderNumber, placedAt, items];
}
