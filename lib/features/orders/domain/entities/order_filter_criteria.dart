import '../../../../core/filters/date_range_filter.dart';
import '../../../../core/filters/presence_filter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/set_utils.dart';
import '../enums/order_deadline_filter.dart';
import '../enums/order_filter_group.dart';
import '../enums/order_status.dart';
import 'order.dart';

/// Everything Orders can be narrowed by: where it is, which platform, when,
/// how much, and what the order is still missing.
///
/// **[statuses] is the raw eight**, and ticking several is how a seller asks
/// for what the old To Ship and Returns presets grouped.
class OrderFilterCriteria {
  const OrderFilterCriteria({
    this.statuses = const <OrderStatus>{},
    this.marketplaceIds = const <String>{},
    this.ordered = DateRangeFilter.any,
    this.payout = PresenceFilter.any,
    this.tracking = PresenceFilter.any,
    this.deadline = OrderDeadlineFilter.any,
    this.minSale,
    this.maxSale,
  });

  /// Nothing narrowed — what Orders opens on and what Reset restores.
  static const OrderFilterCriteria none = OrderFilterCriteria();

  final Set<OrderStatus> statuses;

  /// `Order.marketplaceId` values — the seller's own marketplace record where
  /// there is one, the platform's enum name otherwise.
  final Set<String> marketplaceIds;

  final DateRangeFilter ordered;

  /// Whether the platform has paid out yet. The filter the payout screen's
  /// "awaiting" figure is made of, asked of one list of orders.
  final PresenceFilter payout;

  final PresenceFilter tracking;
  final OrderDeadlineFilter deadline;

  /// The sale-price window. Either end may stand alone.
  final Money? minSale;
  final Money? maxSale;

  /// How many groups are narrowing the list — counted by group, never by
  /// chip. See `ItemFilterCriteria.activeCount`.
  int get activeCount => OrderFilterGroup.values.where(narrows).length;

  /// Whether [group] is narrowing the list — what lights its chip.
  bool narrows(OrderFilterGroup group) => switch (group) {
    OrderFilterGroup.status => statuses.isNotEmpty,
    OrderFilterGroup.marketplace => marketplaceIds.isNotEmpty,
    OrderFilterGroup.ordered => ordered.isActive,
    OrderFilterGroup.deadline => deadline.isActive,
    OrderFilterGroup.payout => payout.isActive,
    OrderFilterGroup.tracking => tracking.isActive,
    OrderFilterGroup.saleRange => minSale != null || maxSale != null,
  };

  /// These criteria with [group] back to "not narrowed" — a one-group
  /// sheet's Reset, which must leave every other group alone.
  OrderFilterCriteria cleared(OrderFilterGroup group) => switch (group) {
    OrderFilterGroup.status => copyWith(statuses: none.statuses),
    OrderFilterGroup.marketplace => copyWith(
      marketplaceIds: none.marketplaceIds,
    ),
    OrderFilterGroup.ordered => copyWith(ordered: none.ordered),
    OrderFilterGroup.deadline => copyWith(deadline: none.deadline),
    OrderFilterGroup.payout => copyWith(payout: none.payout),
    OrderFilterGroup.tracking => copyWith(tracking: none.tracking),
    OrderFilterGroup.saleRange => copyWith(
      clearMinSale: true,
      clearMaxSale: true,
    ),
  };

  bool get isActive => activeCount > 0;

  bool matches(Order order, {required DateTime now}) {
    if (statuses.isNotEmpty && !statuses.contains(order.status)) return false;
    if (marketplaceIds.isNotEmpty &&
        !marketplaceIds.contains(order.marketplaceId)) {
      return false;
    }
    if (!ordered.matches(order.orderedAt, now: now)) return false;
    if (!payout.matches(order.payout != null)) return false;
    if (!tracking.matches(order.trackingNumber != null)) return false;
    if (!deadline.matches(order, now: now)) return false;

    return _matchesSaleRange(order.salePrice);
  }

  /// How many of [orders] each status would show on its own — under every
  /// other group, but not the status group itself.
  Map<OrderStatus, int> statusCounts(
    List<Order> orders, {
    required DateTime now,
  }) {
    final OrderFilterCriteria others = cleared(OrderFilterGroup.status);
    final List<Order> pool = orders
        .where((Order order) => others.matches(order, now: now))
        .toList();

    return <OrderStatus, int>{
      for (final OrderStatus status in OrderStatus.values)
        status: pool.where((Order order) => order.status == status).length,
    };
  }

  /// Ticking a chip, as a value rather than as a write — the reason the
  /// vocabulary lives on the criteria is in `ItemFilterCriteria`.
  OrderFilterCriteria withStatusToggled(OrderStatus value) =>
      copyWith(statuses: SetUtils.toggled(statuses, value));

  OrderFilterCriteria withMarketplaceToggled(String id) =>
      copyWith(marketplaceIds: SetUtils.toggled(marketplaceIds, id));

  OrderFilterCriteria withOrdered(DateRangeFilter value) =>
      copyWith(ordered: value);

  OrderFilterCriteria withPayout(PresenceFilter value) =>
      copyWith(payout: value);

  OrderFilterCriteria withTracking(PresenceFilter value) =>
      copyWith(tracking: value);

  OrderFilterCriteria withDeadline(OrderDeadlineFilter value) =>
      copyWith(deadline: value);

  /// **Null clears that end of the window** — an empty box means unbounded,
  /// never zero.
  OrderFilterCriteria withMinSale(Money? value) =>
      value == null ? copyWith(clearMinSale: true) : copyWith(minSale: value);

  OrderFilterCriteria withMaxSale(Money? value) =>
      value == null ? copyWith(clearMaxSale: true) : copyWith(maxSale: value);

  OrderFilterCriteria copyWith({
    Set<OrderStatus>? statuses,
    Set<String>? marketplaceIds,
    DateRangeFilter? ordered,
    PresenceFilter? payout,
    PresenceFilter? tracking,
    OrderDeadlineFilter? deadline,
    Money? minSale,
    Money? maxSale,
    bool clearMinSale = false,
    bool clearMaxSale = false,
  }) => OrderFilterCriteria(
    statuses: statuses ?? this.statuses,
    marketplaceIds: marketplaceIds ?? this.marketplaceIds,
    ordered: ordered ?? this.ordered,
    payout: payout ?? this.payout,
    tracking: tracking ?? this.tracking,
    deadline: deadline ?? this.deadline,
    // A null means "leave it alone", so emptying a price box needs the flag.
    minSale: clearMinSale ? null : minSale ?? this.minSale,
    maxSale: clearMaxSale ? null : maxSale ?? this.maxSale,
  );

  /// An amount in another currency is out of the window: comparing two
  /// currencies throws (hard rule 4), and there is no rate here to convert
  /// with.
  bool _matchesSaleRange(Money price) {
    final Money? min = minSale;
    final Money? max = maxSale;

    if (min == null && max == null) return true;
    if (min != null &&
        (price.currency != min.currency || price.minor < min.minor)) {
      return false;
    }
    if (max != null &&
        (price.currency != max.currency || price.minor > max.minor)) {
      return false;
    }

    return true;
  }
}
