import '../../../../core/filters/date_range_filter.dart';
import '../../../../core/filters/presence_filter.dart';
import '../../../../core/money/money.dart';
import '../enums/order_deadline_filter.dart';
import '../enums/order_status.dart';
import 'order.dart';

/// Everything Orders can be narrowed by beyond its five tabs.
///
/// The tab strip answers "where is it", one preset at a time. This answers the
/// rest — which platform, when, how much, and what the order is still missing.
/// The two are ANDed, so a tab's count is always the count of what that tab
/// would show.
///
/// **[statuses] overlaps the tabs on purpose.** The strip groups the eight
/// statuses into five presets, and `cancelled` and `awaitingPayment` are not
/// presets of their own — a seller looking for exactly those has nowhere else
/// to ask.
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
  int get activeCount {
    int count = 0;

    if (statuses.isNotEmpty) count++;
    if (marketplaceIds.isNotEmpty) count++;
    if (ordered.isActive) count++;
    if (payout.isActive) count++;
    if (tracking.isActive) count++;
    if (deadline.isActive) count++;
    if (minSale != null || maxSale != null) count++;

    return count;
  }

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
