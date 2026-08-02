import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/write_queue.dart';
import '../../data/models/order.dart';
import '../../data/repositories/orders_repository.dart';
import 'orders_state.dart';

/// Owns the order history. New orders are prepended (most recent first) so the
/// history screen reads top-down chronologically.
///
/// When an [OrdersRepository] is wired in, previously saved orders are
/// restored on construction and every mutation is persisted (fire-and-forget).
/// Store failures are logged and never crash the app.
class OrdersCubit extends Cubit<OrdersState> {
  // Positional-optional so the private field can be an initializing formal
  // (a private *named* parameter would be unusable from other libraries).
  OrdersCubit([this._repository]) : super(const OrdersState()) {
    _restore();
  }

  final OrdersRepository? _repository;

  /// True once the user has mutated the history; a late restore must not
  /// clobber user actions.
  bool _mutated = false;

  /// Serializes persist writes so a burst of checkouts can't land out of order.
  final WriteQueue _writes = WriteQueue();

  Future<void> _restore() async {
    final repository = _repository;
    if (repository == null || isClosed) return;

    try {
      final orders = await repository.loadOrders();
      // Only apply the restored history if the user hasn't mutated anything.
      if (!isClosed && !_mutated && orders.isNotEmpty) {
        emit(OrdersState(orders: orders));
      }
    } catch (error) {
      // A failed store read must not crash the app; start empty.
      debugPrint('Failed to restore orders: $error');
    }
  }

  void _persist() {
    final repository = _repository;
    if (repository == null) return;
    final snapshot = state.orders;
    _writes.enqueue(() async {
      try {
        await repository.saveOrders(snapshot);
      } catch (error) {
        debugPrint('Failed to persist orders: $error');
      }
    });
  }

  /// Appends [order] to the history as the most recent entry.
  void recordOrder(Order order) {
    _mutated = true;
    emit(OrdersState(orders: [order, ...state.orders]));
    _persist();
  }

  void clear() {
    _mutated = true;
    emit(const OrdersState());
    _persist();
  }
}
