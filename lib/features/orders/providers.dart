/// Riverpod wiring for `orders`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../core/constants/log_tag_constant.dart';
import '../../core/time/app_clock.dart';
import '../inventory/domain/entities/item.dart';
import '../inventory/domain/services/item_search.dart';
import '../inventory/providers.dart';
import '../mock_data/providers.dart';
import '../workspace/providers.dart';
import 'domain/entities/order.dart';
import 'domain/entities/order_filter_criteria.dart';
import 'domain/enums/order_status.dart';
import 'domain/services/payout_reconciliation.dart';
import 'presentation/controllers/record_sale_controller.dart';

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

/// The extra filters behind Orders' filter sheet — the same split Inventory
/// has, for the same reason: the strip stays one preset with counts, and the
/// sheet holds the groups a seller opens deliberately.
class OrderCriteriaController extends Notifier<OrderFilterCriteria> {
  @override
  OrderFilterCriteria build() => OrderFilterCriteria.none;

  /// Writes what the filter sheet was holding, once Apply is pressed — see
  /// `InventoryCriteriaController.apply` for why the sheet holds it.
  void apply(OrderFilterCriteria pending) {
    SdLogger.action(
      LogTagConstant.order,
      'Apply order filters',
      <String, Object?>{'groups': pending.activeCount},
    );

    state = pending;
  }

  /// Drops every filter, the tab included.
  void reset() {
    // Not `orderActiveFilterCountProvider` — it watches this notifier, so
    // reading it here is a circular dependency. See Inventory's reset.
    SdLogger.action(
      LogTagConstant.order,
      'Reset order filters',
      <String, Object?>{
        'groups': state.activeCount,
        'tab': ref.read(orderFilterProvider).name,
      },
    );

    ref.read(orderFilterProvider.notifier).select(OrderFilter.all);
    state = OrderFilterCriteria.none;
  }
}

final NotifierProvider<OrderCriteriaController, OrderFilterCriteria>
orderCriteriaProvider =
    NotifierProvider<OrderCriteriaController, OrderFilterCriteria>(
      OrderCriteriaController.new,
    );

/// How many filters are narrowing the list — the tab counted as one whenever
/// it is not `all`. See `inventoryActiveFilterCountProvider`.
final Provider<int> orderActiveFilterCountProvider = Provider<int>((Ref ref) {
  final int extras = ref.watch(orderCriteriaProvider).activeCount;
  final OrderFilter tab = ref.watch(orderFilterProvider);

  return tab == OrderFilter.all ? extras : extras + 1;
});

final Provider<Map<OrderFilter, int>> orderCountsProvider =
    Provider<Map<OrderFilter, int>>((Ref ref) {
      final List<Order> orders =
          ref.watch(ordersProvider).value ?? const <Order>[];
      final OrderFilterCriteria criteria = ref.watch(orderCriteriaProvider);
      final DateTime now = ref.watch(clockProvider).now();

      // Narrowed by the sheet but not by the tab, so a chip's number is
      // exactly how many rows tapping it would show.
      final List<Order> pool = orders
          .where((Order order) => criteria.matches(order, now: now))
          .toList();

      return <OrderFilter, int>{
        for (final OrderFilter filter in OrderFilter.values)
          filter: pool.where(filter.matches).length,
      };
    });

/// Marketplace id → the name to put on a chip, taken from the orders
/// themselves.
///
/// **Read off the orders rather than the marketplace records**, so a filter
/// chip exists for every platform the list actually contains — including one
/// the seller has since deleted, and one an old order names by the platform's
/// own enum rather than by a record id.
final Provider<Map<String, String>> orderMarketplaceNamesProvider =
    Provider<Map<String, String>>((Ref ref) {
      final List<Order> orders =
          ref.watch(ordersProvider).value ?? const <Order>[];

      return <String, String>{
        for (final Order order in orders)
          order.marketplaceId: order.marketplaceName,
      };
    });

final Provider<List<Order>> visibleOrdersProvider = Provider<List<Order>>((
  Ref ref,
) {
  final List<Order> orders = ref.watch(ordersProvider).value ?? const <Order>[];
  final OrderFilter filter = ref.watch(orderFilterProvider);
  final OrderFilterCriteria criteria = ref.watch(orderCriteriaProvider);
  final DateTime now = ref.watch(clockProvider).now();

  return orders
      .where(
        (Order order) =>
            filter.matches(order) && criteria.matches(order, now: now),
      )
      .toList();
});

/// Orders still waiting on the seller, most urgent first.
///
/// **Sorted by deadline, not by date ordered.** The order that has waited
/// longest is not necessarily the one about to breach a shipping window, and
/// the penalty falls on the deadline. Orders with no deadline sort last —
/// they are real work, but nothing external is counting down on them.
final Provider<List<Order>>
ordersNeedingActionProvider = Provider<List<Order>>((Ref ref) {
  final List<Order> orders = ref.watch(ordersProvider).value ?? const <Order>[];

  final List<Order> pending =
      orders.where((Order order) => order.status == OrderStatus.toShip).toList()
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
});

/// What each marketplace has settled and what it still owes.
///
/// Derived at read time like every other figure (hard rule 3): a fee
/// corrected next week changes what this says a platform owes, which is
/// exactly what reconciling a bank statement needs.
final Provider<List<MarketplacePayout>> marketplacePayoutsProvider =
    Provider<List<MarketplacePayout>>((Ref ref) {
      return PayoutReconciliation.byMarketplace(
        ref.watch(ordersProvider).value ?? const <Order>[],
        feeRates: ref.watch(marketplaceFeeRatesProvider),
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

/// The one way an order is written — see `lib/features/orders/CLAUDE.md`.
///
/// Declared here rather than beside the controller because Inventory's Mark
/// as sold sheet and Offers both reach it, and a feature is imported through
/// its `providers.dart`, never through its `presentation/`.
final NotifierProvider<RecordSaleController, bool>
recordSaleControllerProvider = NotifierProvider<RecordSaleController, bool>(
  RecordSaleController.new,
);

/// What the seller has typed into the record-sale picker.
///
/// A controller rather than screen state, per `docs/rules/SCREENS.md`: the
/// query survives a rebuild, and filtering is nobody's job but this.
class RecordSaleQueryController extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;

  void clear() => state = '';
}

final NotifierProvider<RecordSaleQueryController, String>
recordSaleQueryProvider = NotifierProvider<RecordSaleQueryController, String>(
  RecordSaleQueryController.new,
);

/// The rows the record-sale picker shows: what is on the shelf, narrowed by
/// the search box.
final Provider<List<Item>> recordSaleItemsProvider = Provider<List<Item>>((
  Ref ref,
) {
  final List<Item> items = ref.watch(sellableItemsProvider);
  final String query = ref.watch(recordSaleQueryProvider);

  return items.where((Item item) => ItemSearch.matches(item, query)).toList();
});
