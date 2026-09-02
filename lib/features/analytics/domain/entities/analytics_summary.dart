import '../../../../core/money/money.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../../orders/domain/entities/order.dart';

/// The headline numbers, computed from the rows rather than stored.
///
/// **Every money field is nullable, and each null means something specific:**
/// no rows to compute from, or rows whose costs were never entered. Both
/// render as `—` (hard rule 5). A zero here would be a claim — that the
/// seller earned nothing — and the whole point of this type is to avoid
/// making claims the data does not support.
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.revenue,
    required this.netProfit,
    required this.orderCount,
    required this.unitsSold,
    required this.inventoryValue,
    required this.itemsOnHand,
    required this.totalExpenses,
    required this.costOfGoodsSold,
    required this.isProfitComplete,
    required this.hasEstimatedFees,
  });

  /// Fold the rows into the summary.
  ///
  /// [orders] is filtered to those that `countsAsRevenue` — a cancelled order
  /// never earned anything and a refunded one gave it back, so counting
  /// either would make these figures disagree with the seller's bank.
  factory AnalyticsSummary.from({
    required List<Order> orders,
    required List<Item> items,
    required List<Expense> expenses,
    required String currency,
    Map<String, double> feeRates = const <String, double>{},
  }) {
    final Money zero = Money.zero(currency);

    final List<Order> counted = orders
        .where((Order order) => order.status.countsAsRevenue)
        .toList();

    final Money? revenue = counted
        .map((Order order) => order.salePrice - (order.refund ?? zero))
        .totalOrNull();

    final List<Money?> costs = counted
        .map((Order order) => order.costOfGoods)
        .toList();

    final Money? cogs = costs.totalOfKnown();

    // Estimated from the platform's rate where the seller has not entered one
    // — `order.fees ?? zero` claimed every unreported commission was free,
    // which overstated this whole summary (`Order.effectiveFees`).
    final Money? fees = counted
        .map((Order order) => order.effectiveFees(feeRates))
        .totalOrNull();

    final Money? shipping = counted
        .map((Order order) => order.shippingCost ?? zero)
        .totalOrNull();

    // Only expenses NOT already attributed to an order — a shipping label
    // charged to an order is already in that order's `shippingCost`, and
    // counting it twice understates profit.
    final Money? overheads = expenses
        .where((Expense expense) => expense.orderId == null)
        .map((Expense expense) => expense.amount)
        .totalOrNull();

    final Money? profit = (revenue == null || cogs == null)
        ? null
        : revenue -
              cogs -
              (fees ?? zero) -
              (shipping ?? zero) -
              (overheads ?? zero);

    final List<Item> onHand = items
        .where((Item item) => item.status.isOnHand)
        .toList();

    return AnalyticsSummary(
      revenue: revenue,
      netProfit: profit,
      orderCount: counted.length,
      unitsSold: counted.fold(
        0,
        (int total, Order order) => total + order.unitCount,
      ),
      inventoryValue: onHand
          .map((Item item) => item.inventoryValue)
          .totalOfKnown(),
      itemsOnHand: onHand.length,
      totalExpenses: expenses
          .map((Expense expense) => expense.amount)
          .totalOrNull(),
      costOfGoodsSold: cogs,
      // False when any sold item's cost was missing, so the UI can mark the
      // figure partial instead of presenting it as the whole truth.
      isProfitComplete: costs.allKnown && costs.isNotEmpty,
      hasEstimatedFees: counted.any((Order order) => order.feesAreEstimated),
    );
  }

  final Money? revenue;
  final Money? netProfit;
  final int orderCount;
  final int unitsSold;
  final Money? inventoryValue;
  final int itemsOnHand;
  final Money? totalExpenses;
  final Money? costOfGoodsSold;

  /// Whether every sold item had a known cost.
  final bool isProfitComplete;

  /// Whether any counted order's commission was estimated rather than
  /// reported, so the screen can label the figure instead of presenting a
  /// guess as a fact.
  final bool hasEstimatedFees;

  /// Profit as a fraction of revenue, or null when either is unknown.
  double? get margin {
    final Money? profit = netProfit;
    final Money? taken = revenue;

    if (profit == null || taken == null || taken.isZero) return null;

    return profit.ratioOf(taken);
  }

  /// Average revenue per order, or null when there were none.
  Money? get averageOrderValue {
    final Money? taken = revenue;

    if (taken == null || orderCount == 0) return null;

    return Money(taken.minor ~/ orderCount, taken.currency);
  }
}

/// One platform's contribution (plan §9, Marketplace section).
class MarketplacePerformance {
  const MarketplacePerformance({
    required this.marketplaceId,
    required this.marketplaceName,
    required this.revenue,
    required this.profit,
    required this.fees,
    required this.orderCount,
    required this.hasEstimatedFees,
  });

  factory MarketplacePerformance.from({
    required String marketplaceId,
    required String marketplaceName,
    required List<Order> orders,
    required String currency,
    Map<String, double> feeRates = const <String, double>{},
  }) {
    final Money zero = Money.zero(currency);

    final Money revenue =
        orders
            .map((Order order) => order.salePrice - (order.refund ?? zero))
            .totalOrNull() ??
        zero;

    final Money fees =
        orders
            .map((Order order) => order.effectiveFees(feeRates))
            .totalOrNull() ??
        zero;

    final List<Money?> profits = orders
        .map((Order order) => order.profit(feeRates: feeRates).netProfit)
        .toList();

    return MarketplacePerformance(
      marketplaceId: marketplaceId,
      marketplaceName: marketplaceName,
      revenue: revenue,
      profit: profits.totalOfKnown(),
      fees: fees,
      orderCount: orders.length,
      hasEstimatedFees: orders.any((Order order) => order.feesAreEstimated),
    );
  }

  final String marketplaceId;
  final String marketplaceName;

  Marketplace get marketplace => Marketplace.values.firstWhere(
    (Marketplace value) => value.name == marketplaceId,
    orElse: () => Marketplace.other,
  );
  /// Whether any of this platform's orders had its commission estimated
  /// rather than reported, so a row can mark the figure as approximate.
  final bool hasEstimatedFees;

  final Money revenue;

  /// Null when any order on this platform had an unknown cost.
  final Money? profit;

  final Money fees;
  final int orderCount;

  /// What share of revenue the platform took. Null when it earned nothing.
  double? get feeRate => fees.ratioOf(revenue);
}
