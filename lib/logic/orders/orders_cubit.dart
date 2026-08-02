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
  // Without a repository there's nothing to restore, so the state starts
  // "restored"; with one it starts un-restored until [OrdersState.restored]
  // flips — letting deep links wait instead of wrongly showing not-found.
  OrdersCubit([this._repository])
      : super(OrdersState(restored: _repository == null)) {
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
      if (!isClosed && !_mutated) {
        emit(OrdersState(orders: orders, restored: true));
      }
    } catch (error) {
      // A failed store read must not crash the app; mark the state restored
      // (empty) so a deep link can resolve to not-found rather than hang.
      if (!isClosed && !_mutated) {
        emit(const OrdersState(restored: true));
      }
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

  /// Looks up an order by its [orderNumber], or `null` when unknown — used by
  /// the router to resolve `/orders/:orderNumber` deep links.
  Order? orderByNumber(String orderNumber) {
    for (final order in state.orders) {
      if (order.orderNumber == orderNumber) return order;
    }
    return null;
  }

  /// Appends [order] to the history as the most recent entry.
  void recordOrder(Order order) {
    _mutated = true;
    emit(OrdersState(orders: [order, ...state.orders], restored: true));
    _persist();
  }

  void clear() {
    _mutated = true;
    emit(const OrdersState(restored: true));
    _persist();
  }
}
