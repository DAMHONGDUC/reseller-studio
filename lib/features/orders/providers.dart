/// Riverpod wiring for `orders`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../mock_data/providers.dart';
import '../workspace/providers.dart';
import 'domain/entities/order.dart';
import 'domain/enums/order_status.dart';
import 'domain/services/payout_reconciliation.dart';

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
  return WorkspaceGuard.listOrEmpty<Order>(
    ref,
    () => ref.watch(orderRepositoryProvider).watchOrders(),
  );
});

// See `itemProvider` for why the type is inferred rather than written.
// ignore: type_annotate_public_apis
final orderProvider = StreamProvider.family<Order?, String>((
  Ref ref,
  String id,
) {
  return WorkspaceGuard.oneOrNull<Order>(
    ref,
    () => ref.watch(orderRepositoryProvider).watchOrder(id),
  );
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

/// What each marketplace has settled and what it still owes.
///
/// Derived at read time like every other figure (hard rule 3): a fee
/// corrected next week changes what this says a platform owes, which is
/// exactly what reconciling a bank statement needs.
final Provider<List<MarketplacePayout>> marketplacePayoutsProvider =
    Provider<List<MarketplacePayout>>((Ref ref) {
      return PayoutReconciliation.byMarketplace(
        ref.watch(ordersProvider).value ?? const <Order>[],
      );
    });

/// How many orders across every marketplace are still missing a payout.
///
/// What a badge on the More row reads, so a seller sees there is money
/// outstanding without opening the screen.
final Provider<int> ordersAwaitingPayoutProvider = Provider<int>((Ref ref) {
  return ref
      .watch(marketplacePayoutsProvider)
      .fold(
        0,
        (int running, MarketplacePayout row) => running + row.awaiting.length,
      );
});
