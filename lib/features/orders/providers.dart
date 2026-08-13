/// Riverpod wiring for `orders`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../mock_data/providers.dart';
import 'domain/entities/order.dart';
import 'domain/enums/order_status.dart';

/// The tabs across the top of Orders (plan §8).
enum OrderFilter {
  all,
  toShip,
  shipped,
  delivered,
  returns;

  bool matches(Order order) => switch (this) {
    OrderFilter.all => true,
    // `awaitingPayment` is folded in here on purpose: from the seller's point
    // of view both are "not gone yet", and a tab holding a single unpaid
    // order that they must not ship is worse than a note on the row.
    OrderFilter.toShip =>
      order.status == OrderStatus.toShip ||
          order.status == OrderStatus.awaitingPayment,
    OrderFilter.shipped => order.status == OrderStatus.shipped,
    OrderFilter.delivered => order.status == OrderStatus.delivered,
    OrderFilter.returns =>
      order.status == OrderStatus.returnRequested ||
          order.status == OrderStatus.returned ||
          order.status == OrderStatus.refunded,
  };
}

final StreamProvider<List<Order>> ordersProvider = StreamProvider<List<Order>>((
  Ref ref,
) {
  return ref.watch(orderRepositoryProvider).watchOrders();
});

// See `itemProvider` for why the type is inferred rather than written.
// ignore: type_annotate_public_apis
final orderProvider = StreamProvider.family<Order?, String>((
  Ref ref,
  String id,
) {
  return ref.watch(orderRepositoryProvider).watchOrder(id);
});

class OrderFilterController extends Notifier<OrderFilter> {
  @override
  OrderFilter build() => OrderFilter.all;

  void select(OrderFilter filter) => state = filter;
}

final NotifierProvider<OrderFilterController, OrderFilter> orderFilterProvider =
    NotifierProvider<OrderFilterController, OrderFilter>(
      OrderFilterController.new,
    );

final Provider<Map<OrderFilter, int>> orderCountsProvider =
    Provider<Map<OrderFilter, int>>((Ref ref) {
      final List<Order> orders =
          ref.watch(ordersProvider).value ?? const <Order>[];

      return <OrderFilter, int>{
        for (final OrderFilter filter in OrderFilter.values)
          filter: orders.where(filter.matches).length,
      };
    });

final Provider<List<Order>> visibleOrdersProvider = Provider<List<Order>>((
  Ref ref,
) {
  final List<Order> orders = ref.watch(ordersProvider).value ?? const <Order>[];

  return orders.where(ref.watch(orderFilterProvider).matches).toList();
});

/// Orders still waiting on the seller, most urgent first.
///
/// **Sorted by deadline, not by date ordered.** The order that has waited
/// longest is not necessarily the one about to breach a shipping window, and
/// the penalty falls on the deadline. Orders with no deadline sort last —
/// they are real work, but nothing external is counting down on them.
final Provider<List<Order>> ordersNeedingActionProvider = Provider<List<Order>>(
  (Ref ref) {
    final List<Order> orders =
        ref.watch(ordersProvider).value ?? const <Order>[];

    final List<Order> pending =
        orders.where((Order order) => order.status.needsAction).toList()
          ..sort((Order a, Order b) {
            final DateTime? left = a.shipByDate;
            final DateTime? right = b.shipByDate;

            if (left == null && right == null) {
              return a.orderedAt.compareTo(b.orderedAt);
            }
            if (left == null) return 1;
            if (right == null) return -1;

            return left.compareTo(right);
          });

    return pending;
  },
);
