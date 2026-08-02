import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/write_queue.dart';
import '../../data/models/catalogue_preferences.dart';
import '../../data/repositories/catalogue_preferences_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'products_state.dart';

/// Owns the product catalogue lifecycle: initial → loading → loaded / error,
/// plus the search text, category chip and sort that shape the visible list.
///
/// When a [CataloguePreferencesRepository] is wired in, the last-used
/// search/category/sort configuration is applied on the initial load and
/// persisted after every change.
///
/// [loadProducts] distinguishes an initial load from a pull-to-refresh:
/// a refresh keeps the current grid on screen (no Loading emission). On
/// failure the stale list stays, flagged via [ProductsLoaded.refreshFailed],
/// and the flag is cleared at the start of the next refresh so a consecutive
/// failure emits a distinct state (bloc skips equal emits) — letting the UI
/// snackbar fire again.
class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repository, [this._preferencesRepository])
    : super(const ProductsInitial());

  final ProductRepository _repository;
  final CataloguePreferencesRepository? _preferencesRepository;

  /// True while a load is in flight, so overlapping calls are ignored instead
  /// of racing (see [loadProducts]).
  bool _loading = false;

  /// Read the saved preferences at most once, on the first load.
  bool _preferencesLoaded = false;

  /// Serializes preference writes so a fast burst of filter changes (e.g.
  /// per-keystroke search) can't land on disk out of order.
  final WriteQueue _writes = WriteQueue();

  Future<void> loadProducts() async {
    // Ignore an overlapping reload (e.g. a second pull while one is already in
    // flight): without this, two concurrent requests can interleave and a
    // late-failing one would clobber a newer successful load with stale data.
    if (_loading) return;
    _loading = true;
    try {
      final previous = state;

      if (previous is ProductsLoaded) {
        // Pull-to-refresh: keep the grid visible; no Loading emission.
        // Clear the stale failure flag so a consecutive failure emits a
        // distinct state and the UI snackbar can fire again.
        if (previous.refreshFailed) {
          emit(
            ProductsLoaded(
              products: previous.products,
              query: previous.query,
              selectedCategory: previous.selectedCategory,
              sortField: previous.sortField,
              sortDirection: previous.sortDirection,
            ),
          );
        }
        try {
          final products = await _repository.getProducts();
          emit(
            ProductsLoaded(
              products: products,
              query: previous.query,
              selectedCategory: previous.selectedCategory,
              sortField: previous.sortField,
              sortDirection: previous.sortDirection,
            ),
          );
        } catch (error, stackTrace) {
          // Log the real cause for debuggability; the UI shows a snackbar.
          debugPrint('Failed to refresh products: $error\n$stackTrace');
          emit(
            ProductsLoaded(
              products: previous.products,
              query: previous.query,
              selectedCategory: previous.selectedCategory,
              refreshFailed: true,
              sortField: previous.sortField,
              sortDirection: previous.sortDirection,
            ),
          );
        }
        return;
      }

      // Initial (or retry-after-error) load: full loading → loaded / error.
      emit(const ProductsLoading());
      try {
        final products = await _repository.getProducts();
        final preferences = await _loadPreferences();
        emit(
          ProductsLoaded(
            products: products,
            query: preferences?.query ?? '',
            selectedCategory: preferences?.category,
            sortField: preferences?.sortField ?? SortField.featured,
            sortDirection:
                preferences?.sortDirection ?? SortDirection.ascending,
          ),
        );
      } catch (error, stackTrace) {
        debugPrint('Failed to load products: $error\n$stackTrace');
        emit(
          const ProductsError(
            message:
                'We couldn\u2019t load the catalogue right now. '
                'Please check your connection and try again.',
          ),
        );
      }
    } finally {
      _loading = false;
    }
  }

  /// Updates the search text; a no-op unless products are loaded.
  void updateQuery(String query) {
    final loaded = _loadedOrNull();
    if (loaded == null) return;
    emit(
      ProductsLoaded(
        products: loaded.products,
        query: query,
        selectedCategory: loaded.selectedCategory,
        sortField: loaded.sortField,
        sortDirection: loaded.sortDirection,
      ),
    );
    _savePreferences();
  }

  /// Selects a category chip; `null` means "All". No-op unless loaded.
  void selectCategory(String? category) {
    final loaded = _loadedOrNull();
    if (loaded == null) return;
    emit(
      ProductsLoaded(
        products: loaded.products,
        query: loaded.query,
        selectedCategory: category,
        sortField: loaded.sortField,
        sortDirection: loaded.sortDirection,
      ),
    );
    _savePreferences();
  }

  /// Sets how the visible list is ordered; a no-op unless products are loaded.
  void setSort(SortField field, SortDirection direction) {
    final loaded = _loadedOrNull();
    if (loaded == null) return;
    emit(
      ProductsLoaded(
        products: loaded.products,
        query: loaded.query,
        selectedCategory: loaded.selectedCategory,
        sortField: field,
        sortDirection: direction,
      ),
    );
    _savePreferences();
  }

  Future<CataloguePreferences?> _loadPreferences() async {
    final repository = _preferencesRepository;
    if (repository == null || _preferencesLoaded) return null;
    _preferencesLoaded = true;
    try {
      return await repository.load();
    } catch (error) {
      // Corrupt preferences must not take down the catalogue load.
      debugPrint('Failed to load saved preferences: $error');
      return null;
    }
  }

  void _savePreferences() {
    final repository = _preferencesRepository;
    if (repository == null) return;
    final loaded = _loadedOrNull();
    if (loaded == null) return;
    final snapshot = CataloguePreferences(
      query: loaded.query,
      category: loaded.selectedCategory,
      sortField: loaded.sortField,
      sortDirection: loaded.sortDirection,
    );
    _writes.enqueue(() async {
      try {
        await repository.save(snapshot);
      } catch (error) {
        debugPrint('Failed to save preferences: $error');
      }
    });
  }

  ProductsLoaded? _loadedOrNull() {
    if (state case ProductsLoaded loaded) return loaded;
    return null;
  }
}
