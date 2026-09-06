import '../../../../core/money/money.dart';

/// Where a sale's money went, and what was left.
///
/// The plan's profit statement (§9), as a value type:
///
/// ```text
/// Revenue
/// - COGS
/// - Platform fees
/// - Shipping
/// - Other expenses
/// ----------------
/// Net Profit
/// ```
///
/// **[netProfit] is null when any input is unknown, and that is the whole
/// design.** An item whose purchase price nobody entered has an unknowable
/// profit, and hard rule 5 says the app renders `—` rather than a number.
/// Treating the missing cost as zero would report the entire sale price as
/// profit — the single most misleading thing this app could tell a seller,
/// and the reason this returns a nullable rather than defaulting.
///
/// **[fees] is nullable for the same reason and it is the newer half.** The
/// app does not estimate a platform's cut from a published rate any more
/// (hard rule 3): it is measured from the payout, and until that arrives the
/// profit is unknown rather than approximate.
class ProfitBreakdown {
  const ProfitBreakdown({
    required this.revenue,
    required this.cogs,
    required this.fees,
    required this.shipping,
    required this.otherExpenses,
  });

  /// What the buyer paid.
  final Money revenue;

  /// Cost of goods sold — what the seller paid for the item. Null when the
  /// purchase price was never entered.
  final Money? cogs;

  /// Marketplace commission and payment processing, as measured from the
  /// payout. Null when the seller has not recorded what landed.
  final Money? fees;

  /// What shipping cost the seller.
  final Money shipping;

  /// Packaging, mileage, storage — anything from the Expenses feature
  /// attributed to this sale.
  final Money otherExpenses;

  /// Everything the sale cost, or null when [cogs] or [fees] is unknown.
  Money? get totalCost {
    final Money? goods = cogs;
    final Money? cut = fees;

    if (goods == null || cut == null) return null;

    return goods + cut + shipping + otherExpenses;
  }

  /// Revenue minus every cost. Null when any cost is unknown.
  Money? get netProfit {
    final Money? cost = totalCost;

    if (cost == null) return null;

    return revenue - cost;
  }

  /// Profit as a fraction of **revenue** — "how much of each dollar taken did
  /// I keep". Null when profit is unknown or revenue is zero.
  ///
  /// Not to be confused with [roi], which divides by cost. The two answer
  /// different questions and a seller uses both: margin says whether the
  /// price is right, ROI says whether the buy was right.
  double? get margin => netProfit?.ratioOf(revenue);

  /// Profit as a fraction of **cost** — "how hard did my money work".
  ///
  /// Null when profit is unknown or the item was free. A free item that sells
  /// has infinite ROI, which is true and useless; `—` is the honest render.
  double? get roi {
    final Money? profit = netProfit;
    final Money? cost = totalCost;

    if (profit == null || cost == null || cost.isZero) return null;

    return profit.ratioOf(cost);
  }

  /// True when every input was known, so the figures can be presented as
  /// complete rather than partial.
  bool get isComplete => cogs != null && fees != null;
}

/// What a potential buy is worth, before the seller commits to it.
///
/// This is the plan's purchase evaluation (§11) — the calculation a reseller
/// does standing in a thrift store with the item in their hand, which is why
/// it takes estimates rather than records.
class PurchaseEvaluation {
  const PurchaseEvaluation({
    required this.buyPrice,
    required this.expectedSalePrice,
    required this.expectedFees,
    required this.expectedShipping,
    this.targetRoi = defaultTargetRoi,
  });

  /// The ROI a buy must clear to be worth making, when a caller does not say
  /// otherwise.
  ///
  /// 50% is the reseller rule of thumb, and it is what reproduces the plan's
  /// own worked example (§11): a $60 expected sale with $15 of fees and
  /// shipping gives a $30 maximum buy price. Change it per workspace later;
  /// do not change it to make one example come out differently.
  static const double defaultTargetRoi = 0.5;

  /// What it would cost to buy.
  final Money buyPrice;

  /// What the seller thinks it sells for.
  final Money expectedSalePrice;

  /// Marketplace commission at that sale price.
  final Money expectedFees;

  /// What shipping it would cost.
  final Money expectedShipping;

  /// The minimum ROI this buy must clear, as a fraction — `0.5` is 50%.
  final double targetRoi;

  /// Sale price minus the costs that do not depend on the buy price.
  ///
  /// The money available to cover the purchase and still leave a profit —
  /// what [maximumBuyPrice] divides up.
  Money get netAfterSellingCosts =>
      expectedSalePrice - expectedFees - expectedShipping;

  /// Expected profit at [buyPrice].
  Money get expectedProfit => netAfterSellingCosts - buyPrice;

  /// Expected ROI at [buyPrice], or null when the item is free.
  double? get expectedRoi => expectedProfit.ratioOf(buyPrice);

  /// The most a seller can pay and still hit [targetRoi].
  ///
  /// Derived rather than a rule of thumb about the sale price. At a buy price
  /// `B`, profit is `netAfterSellingCosts - B` and ROI is that over `B`.
  /// Setting ROI to the target and solving:
  ///
  /// ```text
  /// (net - B) / B = target
  ///  net - B      = target × B
  ///  net          = B × (1 + target)
  ///  B            = net / (1 + target)
  /// ```
  ///
  /// The plan's example checks out: net = $60 − $15 = $45, target = 0.5, so
  /// `45 / 1.5 = $30`.
  ///
  /// **Can be negative**, and callers must not clamp it to zero. A negative
  /// maximum means the fees and shipping already exceed the sale price — the
  /// item is not worth taking for free, which is exactly what a sourcing
  /// screen needs to say out loud.
  Money get maximumBuyPrice =>
      netAfterSellingCosts.applyRate(1 / (1 + targetRoi));

  /// Whether this buy clears [targetRoi] at the current [buyPrice].
  bool get meetsTarget => buyPrice <= maximumBuyPrice;
}

/// Whether a listed item has gone stale.
///
/// **Stale is a query, not a stored status** (see `docs/DATA_MODEL.md`). An
/// item is stale if it is still listed and has been for longer than the
/// workspace's threshold. Storing it would mean a nightly job flipping
/// thousands of documents, and a seller who reprices would have to wait for
/// that job before the item left the Stale tab.
/// When a business is running out of things to sell.
///
/// **A separate question from staleness, and the opposite one.** Stale is
/// stock that will not move; low is not having stock at all — the first says
/// reprice, the second says go sourcing, and folding them together hides
/// both (plan §22 lists them separately for the same reason).
final class LowStockPolicy {
  /// How few items on hand before the workspace is told, when it has not set
  /// its own.
  ///
  /// 10: below a couple of days' worth for an active reseller, and high
  /// enough to land while there is still time to go and buy something.
  static const int defaultThreshold = 10;

  /// True when there is stock, and less of it than [threshold].
  ///
  /// **Zero is deliberately not low.** A workspace with nothing on hand is a
  /// new one, and telling somebody who has nothing that they have nothing is
  /// the notification that gets notifications turned off.
  static bool isLow(int onHandCount, {int threshold = defaultThreshold}) =>
      onHandCount > 0 && onHandCount < threshold;
}

final class StaleInventoryPolicy {
  /// How long a listing sits before it counts as stale, when the workspace
  /// has not set its own, in days.
  ///
  /// 60 days: long enough that seasonal stock is not flagged the moment it is
  /// out of season, short enough to catch something before a full quarter's
  /// capital is tied up in it.
  ///
  /// Kept as an `int` as well as a [Duration] because `Workspace` stores days
  /// and a `const` default cannot call `.inDays`.
  static const int defaultThresholdDays = 60;

  static const Duration defaultThreshold = Duration(days: defaultThresholdDays);

  /// True when [listedAt] is further back than [threshold].
  ///
  /// A null [listedAt] is **not** stale — it means the item was never listed,
  /// which is a different problem (it belongs in "Items to list") and lumping
  /// the two together hides both.
  static bool isStale(
    DateTime? listedAt, {
    required DateTime now,
    Duration threshold = defaultThreshold,
  }) {
    if (listedAt == null) return false;

    return now.difference(listedAt) > threshold;
  }

  /// How long an item has been sitting, or null if it was never listed.
  static Duration? age(DateTime? listedAt, {required DateTime now}) {
    if (listedAt == null) return null;

    return now.difference(listedAt);
  }
}
