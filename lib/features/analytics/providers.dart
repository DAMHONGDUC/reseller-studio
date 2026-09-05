/// Riverpod wiring for `analytics` — every figure the app reports.
///
/// **Everything here is derived on read** (hard rule 3). Nothing is stored,
/// so correcting a fee on one order silently corrects every total that
/// depends on it, and a report run next year over the same data produces the
/// same number.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/money/money.dart';
import '../../core/time/app_clock.dart';
import '../expenses/domain/entities/expense.dart';
import '../expenses/providers.dart';
import '../inventory/domain/entities/item.dart';
import '../inventory/domain/enums/item_status.dart';
import '../inventory/providers.dart';
import '../marketplaces/providers.dart';
import '../orders/domain/entities/order.dart';
import '../orders/providers.dart';
import '../pricing/domain/services/profit_calculator.dart';
import '../workspace/providers.dart';
import 'domain/entities/analytics_breakdowns.dart';
import 'domain/entities/analytics_summary.dart';

/// The headline figures — Home's overview tiles and the top of Analytics.
final Provider<AnalyticsSummary> analyticsSummaryProvider =
    Provider<AnalyticsSummary>((Ref ref) {
      final List<Order> orders =
          ref.watch(ordersProvider).value ?? const <Order>[];
      final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];
      final List<Expense> expenses =
          ref.watch(expensesProvider).value ?? const <Expense>[];
      final String currency = ref.watch(workspaceCurrencyProvider);

      return AnalyticsSummary.from(
        orders: orders,
        items: items,
        expenses: expenses,
        currency: currency,
        feeRates: ref.watch(marketplaceFeeRatesProvider),
      );
    });

/// What the business sold — the Sales sub-screen (plan §9).
final Provider<SalesMetrics> salesMetricsProvider = Provider<SalesMetrics>((
  Ref ref,
) {
  return SalesMetrics.from(
    orders: ref.watch(ordersProvider).value ?? const <Order>[],
    currency: ref.watch(workspaceCurrencyProvider),
  );
});

/// What the business is holding and how fast it moves — the Inventory
/// sub-screen (plan §9).
final Provider<InventoryMetrics> inventoryMetricsProvider =
    Provider<InventoryMetrics>((Ref ref) {
      return InventoryMetrics.from(
        items: ref.watch(itemsProvider).value ?? const <Item>[],
        now: ref.watch(clockProvider).now(),
        staleThreshold: ref.watch(staleThresholdProvider),
      );
    });

/// Every category, with what it returned — the Categories sub-screen.
///
/// **Revenue is joined from the orders, item by item.** A category's asking
/// prices say what the seller hoped for; only the sales say what it is worth.
/// Items with no category are deliberately absent rather than lumped into an
/// "Other" row: that row would be the biggest one on the screen and would say
/// nothing except that the seller has not categorised their stock.
final Provider<List<CategoryPerformance>> categoryPerformanceProvider =
    Provider<List<CategoryPerformance>>((Ref ref) {
      final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];
      final List<Order> orders =
          ref.watch(ordersProvider).value ?? const <Order>[];

      final Map<String, Money> soldFor = <String, Money>{};

      for (final Order order in orders) {
        if (!order.status.countsAsRevenue) continue;

        for (final OrderLine line in order.lines) {
          soldFor[line.itemId] = line.lineTotal;
        }
      }

      final Map<String, List<Item>> grouped = <String, List<Item>>{};

      for (final Item item in items) {
        final String? categoryId = item.categoryId;

        if (categoryId == null) continue;

        grouped.putIfAbsent(categoryId, () => <Item>[]).add(item);
      }

      final List<CategoryPerformance> rows =
          grouped.entries.map((MapEntry<String, List<Item>> entry) {
            final List<Item> sold = entry.value
                .where((Item item) => item.status == ItemStatus.sold)
                .toList();

            final Money? revenue = sold
                .map((Item item) => soldFor[item.id])
                .totalOfKnown();

            final List<Money?> costs = sold
                .map((Item item) => item.purchasePrice)
                .toList();

            // Null when any sold item has no recorded cost: a partial cost
            // makes the profit above it overstated (hard rule 5).
            final Money? cost = costs.allKnown ? costs.totalOfKnown() : null;

            return CategoryPerformance(
              categoryId: entry.key,
              itemCount: entry.value.length,
              soldCount: sold.length,
              revenue: revenue,
              cost: cost,
              profit: (revenue == null || cost == null) ? null : revenue - cost,
            );
          }).toList()..sort(
            (CategoryPerformance a, CategoryPerformance b) =>
                b.itemCount.compareTo(a.itemCount),
          );

      return rows;
    });

/// Revenue and profit broken down by platform (plan §9).
final Provider<List<MarketplacePerformance>> marketplacePerformanceProvider =
    Provider<List<MarketplacePerformance>>((Ref ref) {
      final List<Order> orders =
          ref.watch(ordersProvider).value ?? const <Order>[];
      final String currency = ref.watch(workspaceCurrencyProvider);
      final Map<String, double> feeRates = ref.watch(
        marketplaceFeeRatesProvider,
      );

      final Map<String, List<Order>> grouped = <String, List<Order>>{};

      for (final Order order in orders) {
        if (!order.status.countsAsRevenue) continue;

        grouped.putIfAbsent(order.marketplaceId, () => <Order>[]).add(order);
      }

      final List<MarketplacePerformance> rows =
          grouped.entries
              .map(
                (MapEntry<String, List<Order>> entry) =>
                    MarketplacePerformance.from(
                      marketplaceId: entry.key,
                      marketplaceName: entry.value.first.marketplaceName,
                      orders: entry.value,
                      currency: currency,
                      feeRates: feeRates,
                    ),
              )
              .toList()
            ..sort(
              (MarketplacePerformance a, MarketplacePerformance b) =>
                  b.revenue.compareTo(a.revenue),
            );

      return rows;
    });

/// Listed items that have sat too long (plan §7, Home's Needs Attention).
final Provider<List<Item>> staleItemsProvider = Provider<List<Item>>((Ref ref) {
  final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];
  final Duration threshold = ref.watch(staleThresholdProvider);
  final DateTime now = ref.watch(clockProvider).now();

  final List<Item> stale =
      items
          .where(
            (Item item) =>
                item.status.isOnHand &&
                StaleInventoryPolicy.isStale(
                  item.listedAt,
                  now: now,
                  threshold: threshold,
                ),
          )
          .toList()
        // Oldest first — the one that has tied up capital longest is the one to
        // act on.
        ..sort(
          (Item a, Item b) => (a.listedAt ?? now).compareTo(b.listedAt ?? now),
        );

  return stale;
});

/// Items on the shelf that are not listed anywhere — "items to list".
///
/// Kept apart from [staleItemsProvider] because they are different problems
/// with different fixes: this one needs a listing, that one needs a price
/// cut. Merging them into one "needs attention" bucket hides both.
final Provider<List<Item>> unlistedItemsProvider = Provider<List<Item>>((
  Ref ref,
) {
  final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];

  return items
      .where(
        (Item item) =>
            item.status == ItemStatus.inStock ||
            item.status == ItemStatus.draft,
      )
      .toList();
});

/// Total cost of everything still on the shelf.
///
/// **At cost, not at asking price.** Retail-value inventory is a number that
/// flatters the seller and is the wrong one for insurance and tax, which is
/// what the figure is actually used for.
final Provider<Money?> inventoryValueProvider = Provider<Money?>((Ref ref) {
  final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];

  return items
      .map((Item item) => item.inventoryValue)
      .where((Money? value) => value != null)
      .totalOfKnown();
});
