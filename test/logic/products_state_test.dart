import 'package:e_commerce/data/models/product.dart';
import 'package:e_commerce/logic/products/products_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const headphones = Product(
    id: '1',
    name: 'Aurora Wireless Headphones',
    description: 'd',
    price: 249.99,
    imageAsset: 'a',
    category: 'Audio',
  );
  const tee = Product(
    id: '2',
    name: 'Breeze Cotton Tee',
    description: 'd',
    price: 24.99,
    imageAsset: 'b',
    category: 'Apparel',
  );
  const watch = Product(
    id: '3',
    name: 'Pulse Smartwatch',
    description: 'd',
    price: 199.99,
    imageAsset: 'c',
    category: 'Wearables',
  );
  const products = [headphones, tee, watch];

  group('ProductsLoaded.filteredProducts', () {
    test('returns everything when no filters are active', () {
      expect(
        const ProductsLoaded(products: products).filteredProducts,
        products,
      );
    });

    test('matches the name case-insensitively', () {
      const state = ProductsLoaded(products: products, query: 'pulse');
      expect(state.filteredProducts, [watch]);
    });

    test('matches the category name too', () {
      const state = ProductsLoaded(products: products, query: 'audio');
      expect(state.filteredProducts, [headphones]);
    });

    test('filters by selected category', () {
      const state = ProductsLoaded(
        products: products,
        selectedCategory: 'Audio',
      );
      expect(state.filteredProducts, [headphones]);
    });

    test('combines query and category (both must match)', () {
      const state = ProductsLoaded(
        products: products,
        query: 'breeze',
        selectedCategory: 'Audio',
      );
      expect(state.filteredProducts, isEmpty);
    });

    test('trims surrounding whitespace from the query', () {
      const state = ProductsLoaded(products: products, query: '  pulse  ');
      expect(state.filteredProducts, [watch]);
    });

    test('two products in the same category are both returned', () {
      const extraTee = Product(
        id: '4',
        name: 'Sunny Cotton Tee',
        description: 'd',
        price: 19.99,
        imageAsset: 'd',
        category: 'Apparel',
      );
      const state = ProductsLoaded(
        products: [tee, extraTee, watch],
        selectedCategory: 'Apparel',
      );
      expect(state.filteredProducts, [tee, extraTee]);
    });
  });

  group('ProductsLoaded.sortedProducts', () {
    test('keeps the catalogue order when sort is featured', () {
      const state = ProductsLoaded(products: products);
      expect(state.sortedProducts, products);
    });

    test('sorts by price ascending', () {
      const state = ProductsLoaded(
        products: products,
        sortField: SortField.price,
        sortDirection: SortDirection.ascending,
      );
      expect(state.sortedProducts, [tee, watch, headphones]);
    });

    test('sorts by price descending', () {
      const state = ProductsLoaded(
        products: products,
        sortField: SortField.price,
        sortDirection: SortDirection.descending,
      );
      expect(state.sortedProducts, [headphones, watch, tee]);
    });

    test('sorts by name ascending (case-insensitive)', () {
      const state = ProductsLoaded(
        products: products,
        sortField: SortField.name,
        sortDirection: SortDirection.ascending,
      );
      // Aurora, Breeze, Pulse — alphabetical by name.
      expect(state.sortedProducts, [headphones, tee, watch]);
    });

    test('sorts by name descending', () {
      const state = ProductsLoaded(
        products: products,
        sortField: SortField.name,
        sortDirection: SortDirection.descending,
      );
      expect(state.sortedProducts, [watch, tee, headphones]);
    });

    test('combines filtering and sorting', () {
      // Query 't' matches Breeze Cotton Tee and Pulse Smartwatch only;
      // price ascending then orders the match by price.
      const state = ProductsLoaded(
        products: products,
        query: 't',
        sortField: SortField.price,
        sortDirection: SortDirection.ascending,
      );
      expect(state.sortedProducts, [tee, watch]);
    });

    test('sorting never mutates the source list', () {
      const state = ProductsLoaded(
        products: products,
        sortField: SortField.price,
        sortDirection: SortDirection.descending,
      );
      expect(state.sortedProducts, isNot(products)); // reordered copy
      expect(state.products, products); // source untouched
    });
  });
}
