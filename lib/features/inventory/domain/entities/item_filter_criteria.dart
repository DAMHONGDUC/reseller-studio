import '../../../../core/filters/date_range_filter.dart';
import '../../../../core/filters/presence_filter.dart';
import '../../../../core/money/money.dart';
import '../../item_filter_constant.dart';
import '../enums/item_status.dart';
import 'item.dart';

/// Everything Inventory can be narrowed by beyond its five tabs.
///
/// **The tab strip and this are two different questions.** `InventoryFilter`
/// is the one preset a seller taps constantly — all, draft, in stock, sold,
/// stale — and it stays a single choice on the strip. This is the rest of the
/// vocabulary: what it is, where it is, where it came from and what is missing
/// from it. The two are ANDed, so a narrowed tab count is still the count of
/// what the tab would show.
///
/// **Empty means "not narrowed", never "nothing".** An empty set matches every
/// item, which is what makes [none] the state the screen opens in.
class ItemFilterCriteria {
  const ItemFilterCriteria({
    this.statuses = const <ItemStatus>{},
    this.conditions = const <ItemCondition>{},
    this.categoryIds = const <String>{},
    this.locationIds = const <String>{},
    this.sourceIds = const <String>{},
    this.photos = PresenceFilter.any,
    this.cost = PresenceFilter.any,
    this.asking = PresenceFilter.any,
    this.listed = PresenceFilter.any,
    this.added = DateRangeFilter.any,
    this.minAsking,
    this.maxAsking,
  });

  /// Nothing narrowed — what Inventory opens on and what Reset restores.
  static const ItemFilterCriteria none = ItemFilterCriteria();

  final Set<ItemStatus> statuses;
  final Set<ItemCondition> conditions;

  /// Ids of the chosen categories, locations and sources, where
  /// `ItemFilterConstant.unassignedId` stands for the items that name none.
  final Set<String> categoryIds;
  final Set<String> locationIds;
  final Set<String> sourceIds;

  /// Whether the item carries a photo at all.
  final PresenceFilter photos;

  /// Whether a cost was ever entered — the filter that finds the rows making
  /// every profit figure in the app read `—`.
  final PresenceFilter cost;

  /// Whether an asking price was ever entered.
  final PresenceFilter asking;

  /// Whether it has ever been live on a marketplace (`listedAt`).
  final PresenceFilter listed;

  /// How recently the item was created.
  final DateRangeFilter added;

  /// The asking-price window. Either end may stand alone — "under £20" is a
  /// question a seller asks far more often than "between £5 and £20".
  final Money? minAsking;
  final Money? maxAsking;

  /// How many groups are narrowing the list — what the seller is told.
  ///
  /// **Counted by group, not by chip.** Three categories ticked is one filter
  /// ("category"), and telling a seller they have three filters on when they
  /// made one choice is a number they cannot reconcile with the sheet.
  int get activeCount {
    int count = 0;

    if (statuses.isNotEmpty) count++;
    if (conditions.isNotEmpty) count++;
    if (categoryIds.isNotEmpty) count++;
    if (locationIds.isNotEmpty) count++;
    if (sourceIds.isNotEmpty) count++;
    if (photos.isActive) count++;
    if (cost.isActive) count++;
    if (asking.isActive) count++;
    if (listed.isActive) count++;
    if (added.isActive) count++;
    if (minAsking != null || maxAsking != null) count++;

    return count;
  }

  bool get isActive => activeCount > 0;

  /// Whether [item] survives every group at once.
  bool matches(Item item, {required DateTime now}) {
    if (statuses.isNotEmpty && !statuses.contains(item.status)) return false;
    if (conditions.isNotEmpty && !conditions.contains(item.condition)) {
      return false;
    }
    if (!_matchesId(categoryIds, item.categoryId)) return false;
    if (!_matchesId(locationIds, item.locationId)) return false;
    if (!_matchesId(sourceIds, item.sourceId)) return false;
    if (!photos.matches(item.photoUrls.isNotEmpty)) return false;
    if (!cost.matches(item.purchasePrice != null)) return false;
    if (!asking.matches(item.askingPrice != null)) return false;
    if (!listed.matches(item.listedAt != null)) return false;
    if (!added.matches(item.createdAt, now: now)) return false;

    return _matchesAskingRange(item.askingPrice);
  }

  ItemFilterCriteria copyWith({
    Set<ItemStatus>? statuses,
    Set<ItemCondition>? conditions,
    Set<String>? categoryIds,
    Set<String>? locationIds,
    Set<String>? sourceIds,
    PresenceFilter? photos,
    PresenceFilter? cost,
    PresenceFilter? asking,
    PresenceFilter? listed,
    DateRangeFilter? added,
    Money? minAsking,
    Money? maxAsking,
    bool clearMinAsking = false,
    bool clearMaxAsking = false,
  }) => ItemFilterCriteria(
    statuses: statuses ?? this.statuses,
    conditions: conditions ?? this.conditions,
    categoryIds: categoryIds ?? this.categoryIds,
    locationIds: locationIds ?? this.locationIds,
    sourceIds: sourceIds ?? this.sourceIds,
    photos: photos ?? this.photos,
    cost: cost ?? this.cost,
    asking: asking ?? this.asking,
    listed: listed ?? this.listed,
    added: added ?? this.added,
    // A null argument means "leave it alone" here too, so emptying the price
    // box needs the flag — the same shape `Item.clearSoldAt` has.
    minAsking: clearMinAsking ? null : minAsking ?? this.minAsking,
    maxAsking: clearMaxAsking ? null : maxAsking ?? this.maxAsking,
  );

  /// A group of ids, where a record naming none of them matches only when the
  /// seller ticked "unassigned".
  static bool _matchesId(Set<String> selected, String? value) {
    if (selected.isEmpty) return true;
    if (value == null) {
      return selected.contains(ItemFilterConstant.unassignedId);
    }

    return selected.contains(value);
  }

  /// **An item with no asking price is out of any price window**, and an
  /// amount in another currency is too: comparing two currencies throws
  /// (hard rule 4), and there is no rate here to convert with.
  bool _matchesAskingRange(Money? price) {
    final Money? min = minAsking;
    final Money? max = maxAsking;

    if (min == null && max == null) return true;
    if (price == null) return false;
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
