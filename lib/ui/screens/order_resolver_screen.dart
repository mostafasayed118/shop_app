import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/orders/orders_cubit.dart';
import '../../logic/orders/orders_state.dart';
import 'not_found_screen.dart';
import 'order_detail_screen.dart';

/// Resolves a `/orders/:orderNumber` deep link against the restored history.
///
/// In-app navigation passes the full [Order] via the route's `extra`, so it
/// never needs this screen. A deep link (no `extra`) may arrive while the
/// history is still being restored — rather than showing "not found"
/// prematurely, this screen waits: a brief spinner until the cubit reports it
/// is restored, the order once found, and a not-found view only for a
/// genuinely unknown order number.
class OrderResolverScreen extends StatelessWidget {
  const OrderResolverScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      // Once restored, stop listening: a later mutation (e.g. a new order)
      // must not rebuild the open detail screen.
      buildWhen: (previous, current) =>
          previous.restored != current.restored,
      builder: (context, state) {
        if (!state.restored) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final order = context.read<OrdersCubit>().orderByNumber(orderNumber);
        if (order == null) {
          return NotFoundScreen(
            message: 'That order isn\u2019t in your history.',
          );
        }
        return OrderDetailScreen(order: order);
      },
    );
  }
}
