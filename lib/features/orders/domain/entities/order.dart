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
    required this.marketplace,
    required this.lines,
    required this.salePrice,
    required this.orderedAt,
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
    this.notes,
  });

  final String id;
  final OrderStatus status;
  final Marketplace marketplace;
  final List<OrderLine> lines;

  /// What the buyer paid in total, before the platform took its cut.
  final Money salePrice;

  final DateTime orderedAt;

  /// The platform's commission. Null until the integration reports it — and
  /// `Marketplace.estimatedFeeRate` is only ever a planning estimate, never
  /// written here.
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

  /// The full profit statement for this order.
  ///
  /// [otherExpenses] is anything from the Expenses feature attributed to this
  /// sale — passed in rather than looked up, because an entity does not reach
  /// into a repository.
  ProfitBreakdown profit({Money? otherExpenses}) {
    final Money zero = Money.zero(salePrice.currency);

    return ProfitBreakdown(
      revenue: salePrice - (refund ?? zero),
      cogs: costOfGoods,
      fees: fees ?? zero,
      shipping: shippingCost ?? zero,
      otherExpenses: otherExpenses ?? zero,
    );
  }

  /// Whether this order is late. Null when the platform gave no deadline.
  bool? isOverdue(DateTime now) {
    final DateTime? deadline = shipByDate;

    if (deadline == null || !status.needsAction) return null;

    return now.isAfter(deadline);
  }

  int get unitCount =>
      lines.fold(0, (int total, OrderLine line) => total + line.quantity);
}
