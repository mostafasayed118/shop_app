import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/products/products_cubit.dart';
import '../../logic/products/products_state.dart';
import '../widgets/status_view.dart';
import 'not_found_screen.dart';
import 'product_detail_screen.dart';

/// Resolves a `/product/:id` deep link against the catalogue once it has
/// loaded.
///
/// In-app navigation passes the full product via the route's `extra`, so it
/// never needs this screen. A deep link (no `extra`) may arrive while the
/// catalogue is still loading — rather than showing "not found" prematurely,
/// this screen waits for the load: a brief spinner while the cubit is
/// initial/loading, the product once loaded, a retry-able error view if the
/// catalogue itself failed to load, and a not-found view only for a genuinely
/// unknown id.
class ProductResolverScreen extends StatelessWidget {
  const ProductResolverScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      // Once resolved (Loaded), stop listening: a later catalogue refresh must
      // not rebuild (and reset, e.g. the quantity stepper of) the open detail
      // screen.
      buildWhen: (previous, current) =>
          previous is! ProductsLoaded || current is! ProductsLoaded,
      builder: (context, state) {
        return switch (state) {
          ProductsInitial() || ProductsLoading() => Scaffold(
            appBar: AppBar(title: const Text('Product')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          ProductsError(:final message) => _CatalogueErrorView(
            message: message,
          ),
          ProductsLoaded() => _resolved(context),
        };
      },
    );
  }

  Widget _resolved(BuildContext context) {
    final product = context.read<ProductsCubit>().productById(productId);
    if (product == null) {
      return NotFoundScreen(message: 'That product isn\u2019t available.');
    }
    return ProductDetailScreen(product: product);
  }
}

/// The catalogue failed to load, so a deep link can't be resolved yet. Offers
/// a retry; on success the cubit emits Loaded and the resolver proceeds.
class _CatalogueErrorView extends StatelessWidget {
  const _CatalogueErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: StatusView(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load products',
        message: message,
        action: FilledButton.icon(
          onPressed: () => context.read<ProductsCubit>().loadProducts(),
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ),
    );
  }
}
