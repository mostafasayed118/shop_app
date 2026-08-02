import 'package:equatable/equatable.dart';

import '../../data/models/product.dart';

/// Immutable snapshot of the wishlist. Membership is a derived getter so it
/// can never drift out of sync with the product list.
class WishlistState extends Equatable {
  const WishlistState({this.products = const []});

  final List<Product> products;

  bool get isEmpty => products.isEmpty;

  bool contains(String productId) => products.any((p) => p.id == productId);

  @override
  List<Object?> get props => [products];
}
