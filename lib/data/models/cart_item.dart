import 'package:equatable/equatable.dart';

import 'product.dart';

/// A [Product] together with the chosen [quantity] in the cart.
class CartItem extends Equatable {
  const CartItem({required this.product, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }

  final Product product;
  final int quantity;

  /// Line total for this item (price × quantity).
  double get total => product.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  @override
  List<Object?> get props => [product, quantity];
}
