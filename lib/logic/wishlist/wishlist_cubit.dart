import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/write_queue.dart';
import '../../data/models/product.dart';
import '../../data/repositories/wishlist_repository.dart';
import 'wishlist_state.dart';

/// Owns the wishlist. Every mutation emits a fresh [WishlistState] so the
/// card hearts, the app-bar badge and the wishlist screen rebuild reactively.
///
/// When a [WishlistRepository] is wired in, a previously saved wishlist is
/// restored on construction and every mutation is persisted (fire-and-forget).
/// Store failures are logged and never crash the app.
class WishlistCubit extends Cubit<WishlistState> {
  // Positional-optional so the private field can be an initializing formal
  // (a private *named* parameter would be unusable from other libraries).
  WishlistCubit([this._repository]) : super(const WishlistState()) {
    _restore();
  }

  final WishlistRepository? _repository;

  /// True once the user has mutated the wishlist; a late restore must not
  /// clobber user actions (even if the wishlist happens to be empty again).
  bool _mutated = false;

  /// Serializes persist writes so a fast burst of toggles can't land on disk
  /// out of order.
  final WriteQueue _writes = WriteQueue();

  Future<void> _restore() async {
    final repository = _repository;
    if (repository == null || isClosed) return;

    try {
      final products = await repository.loadWishlist();
      // Only apply the restored wishlist if the user hasn't mutated anything —
      // a very fast restore racing a user action must not clobber it, even if
      // the user just cleared the wishlist (isEmpty would be true again).
      if (!isClosed && !_mutated && products.isNotEmpty) {
        emit(WishlistState(products: products));
      }
    } catch (error) {
      // A failed store read must not crash the app; start empty.
      debugPrint('Failed to restore wishlist: $error');
    }
  }

  void _persist() {
    final repository = _repository;
    if (repository == null) return;
    final snapshot = state.products;
    _writes.enqueue(() async {
      try {
        await repository.saveWishlist(snapshot);
      } catch (error) {
        debugPrint('Failed to persist wishlist: $error');
      }
    });
  }

  /// Adds [product] to the wishlist, or removes it when already present —
  /// the single affordance behind every heart button.
  void toggle(Product product) {
    if (contains(product.id)) {
      remove(product.id);
    } else {
      _add(product);
    }
  }

  /// Removes [productId] when present; a no-op otherwise.
  void remove(String productId) {
    if (!contains(productId)) return;
    _mutated = true;
    emit(
      WishlistState(
        products: state.products.where((p) => p.id != productId).toList(),
      ),
    );
    _persist();
  }

  void clear() {
    _mutated = true;
    emit(const WishlistState());
    _persist();
  }

  /// Whether [productId] is currently wishlisted (used by the UI to pick the
  /// heart's filled/outlined state and by [toggle]).
  bool contains(String productId) => state.contains(productId);

  void _add(Product product) {
    if (contains(product.id)) return;
    _mutated = true;
    emit(WishlistState(products: [...state.products, product]));
    _persist();
  }
}
