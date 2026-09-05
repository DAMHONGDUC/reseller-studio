import '../../../../core/money/money.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../../pricing/domain/services/profit_calculator.dart';
import '../enums/order_status.dart';

/// One line of an order.
///
/// [unitPrice] is **copied at sale time and never refreshed from the item**.
/// It is what the buyer paid; repricing the item afterwards must not rewrite
/// history, and a report run next year has to produce the same number it
/// produced today.
class OrderLine {
  const OrderLine({
    required this.itemId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    this.unitCost,
  });

  final String itemId;

  /// The item's title as it was when it sold. Denormalised for the same
  /// reason as [unitPrice] — and so an order still reads correctly after the
  /// item is archived.
  final String title;

  final int quantity;
  final Money unitPrice;

  /// What the seller paid per unit. Null when the item's cost was never
  /// entered, which makes this line's profit unknowable.
  final Money? unitCost;

  Money get lineTotal => unitPrice * quantity;

  Money? get lineCost {
    final Money? cost = unitCost;

    if (cost == null) return null;

    return cost * quantity;
  }
}

/// A sale.
///
/// Line items are **embedded rather than a subcollection**: an order has a
/// handful of lines, they are always read with the order, and they never
/// change after the sale — which is exactly when embedding wins.
class Order {
  const Order({
    required this.id,
    required this.status,
    required this.lines,
    required this.salePrice,
    required this.orderedAt,
    this.marketplace = Marketplace.other,
    this.marketplaceRecordId,
    this.marketplaceNameSnapshot,
    this.fees,
    this.shippingCost,
    this.refund,
    this.payout,
    this.externalOrderId,
    this.buyerName,
    this.trackingNumber,
    this.carrier,
    this.shipByDate,
    this.shippedAt,
    this.deliveredAt,
    this.returnRequestedAt,
    this.returnedAt,
    this.refundedAt,
    this.settledAt,
    this.notes,
  });

  final String id;
  final OrderStatus status;
  final Marketplace marketplace;
  final String? marketplaceRecordId;
  final String? marketplaceNameSnapshot;

  String get marketplaceId => marketplaceRecordId ?? marketplace.name;
  String get marketplaceName =>
      marketplaceNameSnapshot ?? marketplace.displayName;
  final List<OrderLine> lines;

  /// What the buyer paid in total, before the platform took its cut.
  final Money salePrice;

  final DateTime orderedAt;

  /// The platform's commission, as the seller reported it.
  ///
  /// **Null means nobody has entered it, and it is never treated as zero.**
  /// There is no marketplace integration to report one (hard rule 10), so
  /// this arrives only when a seller types what the platform actually took.
  /// Until then every figure that needs a fee uses [effectiveFees] and says
  /// it is an estimate — a zero here would claim the platform worked for
  /// free, which on Poshmark overstates profit by a fifth of the sale price.
  final Money? fees;

  final Money? shippingCost;
  final Money? refund;

  /// What the marketplace actually paid out.
  ///
  /// **The one stored figure that is not derived** (see `docs/DATA_MODEL.md`)
  /// — it is a fact the platform reported, not a calculation, and it is what
  /// the seller reconciles their bank against.
  final Money? payout;

  final String? externalOrderId;
  final String? buyerName;
  final String? trackingNumber;
  final String? carrier;

  /// The platform's shipping deadline. What the shipping queue sorts by —
  /// oldest deadline first, because that is the order at risk of a late
  /// shipment penalty.
  final DateTime? shipByDate;

  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? returnRequestedAt;
  final DateTime? returnedAt;
  final DateTime? refundedAt;
  final DateTime? settledAt;
  final String? notes;

  /// Cost of goods across every line, or null when any line's cost is
  /// unknown.
  ///
  /// Null rather than a partial sum: a profit figure built on some of the
  /// costs is overstated, and hard rule 5 says say nothing rather than say
  /// something wrong.
  Money? get costOfGoods {
    if (lines.isEmpty) return null;

    final List<Money?> costs = lines
        .map((OrderLine line) => line.lineCost)
        .toList();

    if (costs.any((Money? cost) => cost == null)) return null;

    return costs.cast<Money>().reduce((Money a, Money b) => a + b);
  }

  /// What this order's platform charges, as a fraction of the sale price.
  ///
  /// **One resolution, asked by everything that needs a fee** — the profit
  /// statement, the payout forecast and the marketplace breakdown all come
  /// here, so they cannot disagree about what eBay takes. [rates] is
  /// `marketplaceFeeRatesProvider`: the seller's own marketplace records, so a
  /// rate corrected on that screen lands on every past order's estimate.
  ///
  /// The enum's published rate is the fallback for an order that names no
  /// record — a legacy row, or one imported before the records existed.
  double feeRate(Map<String, double> rates) =>
      rates[marketplaceId] ?? marketplace.estimatedFeeRate;

  /// Whether nobody has entered what the platform actually charged.
  bool get feesAreEstimated => fees == null;

  /// What the platform took: reported when the seller entered it, estimated
  /// from [feeRate] when they have not.
  Money effectiveFees(Map<String, double> feeRates) =>
      fees ?? salePrice.applyRate(feeRate(feeRates));

  /// The full profit statement for this order.
  ///
  /// [otherExpenses] is anything from the Expenses feature attributed to this
  /// sale — passed in rather than looked up, because an entity does not reach
  /// into a repository. [feeRates] is passed the same way and for the same
  /// reason.
  ///
  /// **An unreported fee is estimated, never zeroed**, and the breakdown
  /// carries `feesAreEstimated` so the screen can label it.
  ProfitBreakdown profit({
    Money? otherExpenses,
    Map<String, double> feeRates = const <String, double>{},
  }) {
    final Money zero = Money.zero(salePrice.currency);

    return ProfitBreakdown(
      revenue: salePrice - (refund ?? zero),
      cogs: costOfGoods,
      fees: effectiveFees(feeRates),
      shipping: shippingCost ?? zero,
      otherExpenses: otherExpenses ?? zero,
      feesAreEstimated: feesAreEstimated,
    );
  }

  /// Whether this order is late. Null when the platform gave no deadline.
  bool? isOverdue(DateTime now) {
    final DateTime? deadline = shipByDate;

    if (deadline == null || status != OrderStatus.toShip) return null;

    return now.isAfter(deadline);
  }

  int get unitCount =>
      lines.fold(0, (int total, OrderLine line) => total + line.quantity);

  /// A copy with some fields changed.
  ///
  /// **[lines], [salePrice] and [orderedAt] are deliberately not settable.**
  /// They are what the buyer bought, what they paid and when — history, not
  /// state. A correction to any of them is a different order, and letting a
  /// shipping update rewrite them is how a report run next year stops
  /// reproducing this year's number.
  /// A copy with some fields replaced.
  ///
  /// **A null argument means "leave it alone"**, so unsetting a field needs
  /// its own flag. The detail screen's sections can empty a box, and an
  /// emptied box is the seller removing the value — a meaning a bare null
  /// cannot carry.
  Order copyWith({
    OrderStatus? status,
    Money? salePrice,
    DateTime? orderedAt,
    Money? fees,
    Money? shippingCost,
    Money? refund,
    Money? payout,
    String? buyerName,
    String? trackingNumber,
    String? carrier,
    DateTime? shipByDate,
    bool clearFees = false,
    bool clearShippingCost = false,
    bool clearBuyerName = false,
    bool clearTrackingNumber = false,
    bool clearCarrier = false,
    bool clearShipByDate = false,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? returnRequestedAt,
    DateTime? returnedAt,
    DateTime? refundedAt,
    DateTime? settledAt,
    String? notes,
  }) => Order(
    id: id,
    status: status ?? this.status,
    marketplaceRecordId: marketplaceId,
    marketplaceNameSnapshot: marketplaceName,
    lines: lines,
    salePrice: salePrice ?? this.salePrice,
    orderedAt: orderedAt ?? this.orderedAt,
    fees: clearFees ? null : fees ?? this.fees,
    shippingCost: clearShippingCost ? null : shippingCost ?? this.shippingCost,
    refund: refund ?? this.refund,
    payout: payout ?? this.payout,
    externalOrderId: externalOrderId,
    buyerName: clearBuyerName ? null : buyerName ?? this.buyerName,
    trackingNumber: clearTrackingNumber
        ? null
        : trackingNumber ?? this.trackingNumber,
    carrier: clearCarrier ? null : carrier ?? this.carrier,
    shipByDate: clearShipByDate ? null : shipByDate ?? this.shipByDate,
    shippedAt: shippedAt ?? this.shippedAt,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    returnRequestedAt: returnRequestedAt ?? this.returnRequestedAt,
    returnedAt: returnedAt ?? this.returnedAt,
    refundedAt: refundedAt ?? this.refundedAt,
    settledAt: settledAt ?? this.settledAt,
    notes: notes ?? this.notes,
  );
}
