import 'package:equatable/equatable.dart';

import '../../data/models/product.dart';
import '../../data/models/product_sort.dart';

// Sort enums are domain data — re-exported here so existing consumers of
// this file keep compiling unchanged.
export '../../data/models/product_sort.dart' show SortField, SortDirection;

/// State of the product catalogue, following the Loading / Success / Error /
/// Empty discipline from INSTRUCTIONS.md §C.
///
/// Sealed so the compiler can prove switch expressions over it are exhaustive.
sealed class ProductsState extends Equatable {
  const ProductsState();
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();

  @override
  List<Object?> get props => [];
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();

  @override
  List<Object?> get props => [];
}

class ProductsLoaded extends ProductsState {
  const ProductsLoaded({
    required this.products,
    this.query = '',
    this.selectedCategory,
    this.refreshFailed = false,
    this.sortField = SortField.featured,
    this.sortDirection = SortDirection.ascending,
  });

  final List<Product> products;

  /// Current search text (filters [products] via [filteredProducts]).
  final String query;

  /// Currently selected category chip, or `null` for "All".
  final String? selectedCategory;

  /// True when a pull-to-refresh failed and [products] is stale data kept on
  /// screen; the UI surfaces a transient snackbar via BlocListener.
  final bool refreshFailed;

  /// How the visible list is ordered; [SortField.featured] keeps the
  /// catalogue order.
  final SortField sortField;

  /// Order applied on top of [sortField].
  final SortDirection sortDirection;

  /// The full catalogue narrowed by [query] and [selectedCategory].
  ///
  /// Filtering lives on the state — not in widgets — so it is pure, reactive
  /// and unit-testable.
  List<Product> get filteredProducts {
    final search = query.trim().toLowerCase();
    return products.where((product) {
      final matchesSearch = search.isEmpty ||
          product.name.toLowerCase().contains(search) ||
          product.category.toLowerCase().contains(search);
      final matchesCategory =
          selectedCategory == null || product.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  /// [filteredProducts] ordered by [sortField] / [sortDirection].
  ///
  /// "Featured" preserves the catalogue order, and the source list is never
  /// mutated — sorting works on a copy.
  List<Product> get sortedProducts {
    final result = filteredProducts;
    if (sortField == SortField.featured) return result;

    final sorted = List<Product>.of(result);
    final ascending = sortDirection == SortDirection.ascending;
    switch (sortField) {
      case SortField.price:
        sorted.sort((a, b) => ascending
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
      case SortField.name:
        sorted.sort((a, b) {
          final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return ascending ? byName : -byName;
        });
      case SortField.featured:
        break; // Handled by the early return above.
    }
    return sorted;
  }

  @override
  List<Object?> get props => [
    products,
    query,
    selectedCategory,
    refreshFailed,
    sortField,
    sortDirection,
  ];
}

class ProductsError extends ProductsState {
  const ProductsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
