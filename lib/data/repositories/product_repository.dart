import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/product.dart';

/// Reads the product catalogue from the bundled JSON asset and simulates a
/// short network latency so loading states are real (and testable).
///
/// This is the **single swap point** for a real backend later: reimplement
/// [getProducts] with an HTTP call and nothing else in the app changes.
class ProductRepository {
  ProductRepository({
    this.assetPath = 'assets/data/products.json',
    this.delay = const Duration(milliseconds: 700),
  });

  final String assetPath;
  final Duration delay;

  Future<List<Product>> getProducts() async {
    // Simulated latency — delete this once a real data source exists.
    await Future<void>.delayed(delay);

    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
