import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/product.dart';
import '../../logic/cart/cart_cubit.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/cart_button.dart';
import '../widgets/owned_snack_bar.dart';
import '../widgets/price_text.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_selector.dart';

/// Full product view: hero image, description, quantity stepper, add to cart.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with OwnedSnackBar<ProductDetailScreen> {
  int _quantity = 1;

  Product get _product => widget.product;

  void _addToCart() {
    context.read<CartCubit>().addProduct(_product, quantity: _quantity);
    showOwnedToast('$_quantity \u00d7 ${_product.name} added to cart');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_product.name), actions: const [CartButton()]),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ProductImage(product: _product),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product.category.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _product.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                PriceText(
                  _product.price,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _product.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        leading: QuantitySelector(
          quantity: _quantity,
          onIncrement: () => setState(() => _quantity++),
          onDecrement: () => setState(() => _quantity--),
        ),
        button: FilledButton.icon(
          onPressed: _addToCart,
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Add to cart'),
        ),
      ),
    );
  }
}
