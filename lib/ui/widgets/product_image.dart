import 'package:flutter/material.dart';

import '../../data/models/product.dart';

/// The catalogue image for [product], wrapped in a [Hero] with a stable tag
/// (`product-image-<id>`) so the same image animates seamlessly between the
/// grid card and the detail screen.
///
/// Renders the square (1:1) crop used across the catalogue and detail views.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'product-image-${product.id}',
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.asset(product.imageAsset, fit: BoxFit.cover),
      ),
    );
  }
}
