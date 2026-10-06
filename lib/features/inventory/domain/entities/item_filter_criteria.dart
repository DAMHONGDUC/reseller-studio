import '../../../../core/filters/date_range_filter.dart';
import '../../../../core/filters/presence_filter.dart';
import '../../../../core/utils/set_utils.dart';
import '../../item_filter_constant.dart';
import '../enums/item_filter_group.dart';
import '../enums/item_status.dart';
import 'item.dart';

/// Everything Inventory can be narrowed by beyond its Show preset.
///
/// **The preset and this are two different questions.** `InventoryFilter`
/// is one single choice — all, draft, in stock, sold, stale. This is the rest
/// of the vocabulary: what it is, where it is, where it came from and what is
/// missing from it. The two are ANDed, so a preset's count is still the count
/// of what that preset would show.
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
    this.listed = PresenceFilter.any,
    this.added = DateRangeFilter.any,
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

  /// Whether it has ever been live on a marketplace (`listedAt`).
  final PresenceFilter listed;

  /// How recently the item was created.
  final DateRangeFilter added;

  /// How many groups are narrowing the list — what the seller is told.
  ///
  /// **Counted by group, not by chip.** Three categories ticked is one filter
  /// ("category"), and telling a seller they have three filters on when they
  /// made one choice is a number they cannot reconcile with the sheet.
  int get activeCount => ItemFilterGroup.values.where(narrows).length;

  /// Whether [group] is narrowing the list — what lights its chip.
  bool narrows(ItemFilterGroup group) => switch (group) {
    ItemFilterGroup.status => statuses.isNotEmpty,
    ItemFilterGroup.condition => conditions.isNotEmpty,
    ItemFilterGroup.category => categoryIds.isNotEmpty,
    ItemFilterGroup.location => locationIds.isNotEmpty,
    ItemFilterGroup.source => sourceIds.isNotEmpty,
    ItemFilterGroup.photos => photos.isActive,
    ItemFilterGroup.cost => cost.isActive,
    ItemFilterGroup.listed => listed.isActive,
    ItemFilterGroup.added => added.isActive,
  };

  /// These criteria with [group] back to "not narrowed" — a one-group
  /// sheet's Reset, which must leave every other group alone.
  ItemFilterCriteria cleared(ItemFilterGroup group) => switch (group) {
    ItemFilterGroup.status => copyWith(statuses: none.statuses),
    ItemFilterGroup.condition => copyWith(conditions: none.conditions),
    ItemFilterGroup.category => copyWith(categoryIds: none.categoryIds),
    ItemFilterGroup.location => copyWith(locationIds: none.locationIds),
    ItemFilterGroup.source => copyWith(sourceIds: none.sourceIds),
    ItemFilterGroup.photos => copyWith(photos: none.photos),
    ItemFilterGroup.cost => copyWith(cost: none.cost),
    ItemFilterGroup.listed => copyWith(listed: none.listed),
    ItemFilterGroup.added => copyWith(added: none.added),
  };

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
    if (!listed.matches(item.listedAt != null)) return false;
    if (!added.matches(item.createdAt, now: now)) return false;

    return true;
  }

  /// Ticking a chip, as a value rather than as a write.
  ///
  /// **The vocabulary lives here, not on the controller** — the filter sheet
  /// edits a draft it holds until Apply is pressed, and the applied criteria
  /// live in a provider. Two places tick a chip, so what a tick *means* is one
  /// thing in one place; a second copy on the notifier is how the pending
  /// filter and the applied one would come to disagree about a second tap.
  ItemFilterCriteria withStatusToggled(ItemStatus value) =>
      copyWith(statuses: SetUtils.toggled(statuses, value));

  ItemFilterCriteria withConditionToggled(ItemCondition value) =>
      copyWith(conditions: SetUtils.toggled(conditions, value));

  ItemFilterCriteria withCategoryToggled(String id) =>
      copyWith(categoryIds: SetUtils.toggled(categoryIds, id));

  ItemFilterCriteria withLocationToggled(String id) =>
      copyWith(locationIds: SetUtils.toggled(locationIds, id));

  ItemFilterCriteria withSourceToggled(String id) =>
      copyWith(sourceIds: SetUtils.toggled(sourceIds, id));

  ItemFilterCriteria withPhotos(PresenceFilter value) =>
      copyWith(photos: value);

  ItemFilterCriteria withCost(PresenceFilter value) => copyWith(cost: value);

  ItemFilterCriteria withListed(PresenceFilter value) =>
      copyWith(listed: value);

  ItemFilterCriteria withAdded(DateRangeFilter value) => copyWith(added: value);

  ItemFilterCriteria copyWith({
    Set<ItemStatus>? statuses,
    Set<ItemCondition>? conditions,
    Set<String>? categoryIds,
    Set<String>? locationIds,
    Set<String>? sourceIds,
    PresenceFilter? photos,
    PresenceFilter? cost,
    PresenceFilter? listed,
    DateRangeFilter? added,
  }) => ItemFilterCriteria(
    statuses: statuses ?? this.statuses,
    conditions: conditions ?? this.conditions,
    categoryIds: categoryIds ?? this.categoryIds,
    locationIds: locationIds ?? this.locationIds,
    sourceIds: sourceIds ?? this.sourceIds,
    photos: photos ?? this.photos,
    cost: cost ?? this.cost,
    listed: listed ?? this.listed,
    added: added ?? this.added,
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
}
