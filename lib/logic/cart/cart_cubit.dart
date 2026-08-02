import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/write_queue.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../data/repositories/cart_repository.dart';
import 'cart_state.dart';

/// Owns the shopping cart. Every mutation emits a fresh [CartState] so the
/// UI (badge, totals) rebuilds reactively.
///
/// When a [CartRepository] is wired in, a previously saved cart is restored
/// on construction and every mutation is persisted (fire-and-forget). Store
/// failures are logged and never crash the app.
class CartCubit extends Cubit<CartState> {
  // Positional-optional so the private field can be an initializing formal
  // (a private *named* parameter would be unusable from other libraries).
  CartCubit([this._repository]) : super(const CartState()) {
    _restore();
  }

  final CartRepository? _repository;

  /// True once the user has mutated the cart; a late restore must not
  /// clobber user actions (even if the cart happens to be empty again).
  bool _mutated = false;

  /// Serializes persist writes so a fast burst of mutations can't land on
  /// disk out of order (each write snapshots its own state at call time).
  final WriteQueue _writes = WriteQueue();

  Future<void> _restore() async {
    final repository = _repository;
    if (repository == null || isClosed) return;

    try {
      final items = await repository.loadCart();
      // Only apply the restored cart if the user hasn't mutated anything — a
      // very fast restore racing a user action must not clobber it, even if
      // the user just cleared the cart (state.isEmpty would be true again).
      if (!isClosed && !_mutated && items.isNotEmpty) {
        emit(CartState(items: items));
      }
    } catch (error) {
      // A failed store read must not crash the app; start empty.
      debugPrint('Failed to restore cart: $error');
    }
  }

  void _persist() {
    final repository = _repository;
    if (repository == null) return;
    final snapshot = state.items;
    _writes.enqueue(() async {
      try {
        await repository.saveCart(snapshot);
      } catch (error) {
        debugPrint('Failed to persist cart: $error');
      }
    });
  }

  /// Adds [quantity] of [product]; merges into the existing line if the same
  /// product is already in the cart.
  void addProduct(Product product, {int quantity = 1}) {
    if (quantity <= 0) return;
    _mutated = true;
    final items = List<CartItem>.of(state.items);
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final existing = items[index];
      items[index] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      items.add(CartItem(product: product, quantity: quantity));
    }
    emit(CartState(items: items));
    _persist();
  }

  void incrementQuantity(String productId) {
    final item = _itemById(productId);
    if (item != null) updateQuantity(productId, item.quantity + 1);
  }

  /// Decreases by one; the line is removed when it would drop below 1.
  void decrementQuantity(String productId) {
    final item = _itemById(productId);
    if (item != null) updateQuantity(productId, item.quantity - 1);
  }

  /// Sets an absolute quantity; a value of 0 (or less) removes the line.
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    _mutated = true;
    emit(
      CartState(
        items: state.items
            .map(
              (item) => item.product.id == productId
                  ? item.copyWith(quantity: quantity)
                  : item,
            )
            .toList(),
      ),
    );
    _persist();
  }

  void removeProduct(String productId) {
    _mutated = true;
    emit(
      CartState(
        items: state.items
            .where((item) => item.product.id != productId)
            .toList(),
      ),
    );
    _persist();
  }

  void clear() {
    _mutated = true;
    emit(const CartState());
    _persist();
  }

  CartItem? _itemById(String productId) {
    for (final item in state.items) {
      if (item.product.id == productId) return item;
    }
    return null;
  }
}
