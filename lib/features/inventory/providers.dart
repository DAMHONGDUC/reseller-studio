/// Riverpod wiring for `inventory`. Other features import this file, never
/// anything under `inventory/data/` or `inventory/presentation/`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../mock_data/providers.dart';
import '../pricing/domain/services/profit_calculator.dart';
import 'domain/entities/item.dart';
import 'domain/entities/item_category.dart';
import 'domain/entities/storage_location.dart';
import 'domain/enums/item_status.dart';

/// The tabs across the top of Inventory (plan §7).
///
/// **[stale] is not an [ItemStatus]** and this enum is where the difference
/// becomes visible: four of these map to a status, and one is a question
/// about how long something has been listed. See `StaleInventoryPolicy`.
enum InventoryFilter {
  all,
  listed,
  reserved,
  sold,
  stale;

  String get label => switch (this) {
    InventoryFilter.all => 'All',
    InventoryFilter.listed => 'Listed',
    InventoryFilter.reserved => 'Reserved',
    InventoryFilter.sold => 'Sold',
    InventoryFilter.stale => 'Stale',
  };

  /// Whether [item] belongs under this tab.
  bool matches(Item item, {required DateTime now, Duration? staleThreshold}) =>
      switch (this) {
        InventoryFilter.all => true,
        InventoryFilter.listed => item.status == ItemStatus.listed,
        InventoryFilter.reserved => item.status == ItemStatus.reserved,
        InventoryFilter.sold => item.status == ItemStatus.sold,
        InventoryFilter.stale =>
          item.status == ItemStatus.listed &&
              StaleInventoryPolicy.isStale(
                item.listedAt,
                now: now,
                threshold:
                    staleThreshold ?? StaleInventoryPolicy.defaultThreshold,
              ),
      };
}

/// Every item in the workspace, live.
final StreamProvider<List<Item>> itemsProvider = StreamProvider<List<Item>>((
  Ref ref,
) {
  return ref.watch(itemRepositoryProvider).watchItems();
});

/// One item, live — what the detail screen watches so an edit made on another
/// device (or by a teammate) appears without a reload.
///
// The type is inferred rather than written: Riverpod 3 declares
// `StreamProviderFamily` but does not export it from `riverpod.dart`, so it
// cannot be named here. The generic arguments on `.family` carry the same
// information.
// ignore: type_annotate_public_apis
final itemProvider = StreamProvider.family<Item?, String>((Ref ref, String id) {
  return ref.watch(itemRepositoryProvider).watchItem(id);
});

/// Which tab is selected.
class InventoryFilterController extends Notifier<InventoryFilter> {
  @override
  InventoryFilter build() => InventoryFilter.all;

  void select(InventoryFilter filter) => state = filter;
}

final NotifierProvider<InventoryFilterController, InventoryFilter>
inventoryFilterProvider =
    NotifierProvider<InventoryFilterController, InventoryFilter>(
      InventoryFilterController.new,
    );

/// The free-text search box above the list.
class InventorySearchController extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final NotifierProvider<InventorySearchController, String>
inventorySearchProvider = NotifierProvider<InventorySearchController, String>(
  InventorySearchController.new,
);

/// How many items sit under each tab.
///
/// **Computed from the one item stream rather than five queries.** Inventory
/// shows all five counts at once, so per-tab queries would mean five live
/// listeners for one screen; folding over the list already in memory costs
/// nothing and cannot disagree with the list being displayed.
final Provider<Map<InventoryFilter, int>> inventoryCountsProvider =
    Provider<Map<InventoryFilter, int>>((Ref ref) {
      final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];
      final DateTime now = DateTime.now();

      return <InventoryFilter, int>{
        for (final InventoryFilter filter in InventoryFilter.values)
          filter: items
              .where((Item item) => filter.matches(item, now: now))
              .length,
      };
    });

/// Which rows are ticked for a bulk action.
///
/// **Bulk is a first-class requirement, not a later nicety** (hard rule 16):
/// reprice, relist and archive are things a seller does to forty rows at
/// once, and a screen that only edits one item at a time is why people keep
/// using spreadsheets.
///
/// Selection lives in a provider rather than the screen's `State` so the
/// action sheet — a different subtree, pushed on the root navigator — can read
/// it without the screen passing it down.
class InventorySelectionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  bool get isActive => state.isNotEmpty;

  void toggle(String itemId) {
    final Set<String> next = Set<String>.of(state);

    if (!next.remove(itemId)) next.add(itemId);

    state = next;
  }

  void selectAll(Iterable<String> itemIds) =>
      state = Set<String>.of(itemIds);

  void clear() => state = const <String>{};
}

final NotifierProvider<InventorySelectionController, Set<String>>
inventorySelectionProvider =
    NotifierProvider<InventorySelectionController, Set<String>>(
      InventorySelectionController.new,
    );

/// The selected items themselves, resolved from the visible list.
///
/// Derived rather than stored alongside the ids: an item edited by a teammate
/// while a bulk selection is open must reach the action with its new values,
/// and a copy taken at tick time would not.
final Provider<List<Item>> selectedItemsProvider = Provider<List<Item>>((
  Ref ref,
) {
  final Set<String> ids = ref.watch(inventorySelectionProvider);

  if (ids.isEmpty) return const <Item>[];

  final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];

  return items.where((Item item) => ids.contains(item.id)).toList();
});

/// Every category in the workspace — small, slow-changing reference data, so
/// one live stream that every picker and every row folds over.
final StreamProvider<List<ItemCategory>> categoriesProvider =
    StreamProvider<List<ItemCategory>>((Ref ref) {
      return ref.watch(categoryRepositoryProvider).watchCategories();
    });

final StreamProvider<List<StorageLocation>> locationsProvider =
    StreamProvider<List<StorageLocation>>((Ref ref) {
      return ref.watch(locationRepositoryProvider).watchLocations();
    });

/// Category id → name, for rendering a row without looking one up per item.
final Provider<Map<String, String>> categoryNamesProvider =
    Provider<Map<String, String>>((Ref ref) {
      final List<ItemCategory> categories =
          ref.watch(categoriesProvider).value ?? const <ItemCategory>[];

      return <String, String>{
        for (final ItemCategory category in categories)
          category.id: category.name,
      };
    });

/// Location id → its full path, `Garage · Shelf A · Bin A1`.
///
/// The path rather than the leaf, because "Bin A1" alone does not tell a
/// seller which room to walk into — and that is the entire question the
/// Locations feature answers.
final Provider<Map<String, String>> locationPathsProvider =
    Provider<Map<String, String>>((Ref ref) {
      final List<StorageLocation> locations =
          ref.watch(locationsProvider).value ?? const <StorageLocation>[];

      final Map<String, StorageLocation> byId = <String, StorageLocation>{
        for (final StorageLocation location in locations)
          location.id: location,
      };

      return <String, String>{
        for (final StorageLocation location in locations)
          location.id: LocationPathBuilder.pathOf(location, byId),
      };
    });

/// Walks a location up to its warehouse and joins the names.
///
/// Its own class rather than a closure inside the provider: it is string
/// building over a tree, which is not what a provider is for, and the
/// Locations screen needs the same walk.
final class LocationPathBuilder {
  /// How deep the walk is allowed to go before it gives up.
  ///
  /// The tree is warehouse → shelf → bin, so four is already generous. The
  /// cap exists because a corrupted `parentId` cycle would otherwise hang the
  /// UI thread rather than render a slightly wrong label.
  static const int maxDepth = 4;

  static const String separator = ' · ';

  static String pathOf(
    StorageLocation location,
    Map<String, StorageLocation> byId,
  ) {
    final List<String> parts = <String>[location.name];

    String? parentId = location.parentId;
    int depth = 0;

    while (parentId != null && depth < maxDepth) {
      final StorageLocation? parent = byId[parentId];

      if (parent == null) break;

      parts.insert(0, parent.name);
      parentId = parent.parentId;
      depth++;
    }

    return parts.join(separator);
  }
}

/// The rows actually shown: the selected tab, narrowed by the search box.
final Provider<List<Item>> visibleItemsProvider = Provider<List<Item>>((
  Ref ref,
) {
  final List<Item> items = ref.watch(itemsProvider).value ?? const <Item>[];
  final InventoryFilter filter = ref.watch(inventoryFilterProvider);
  final String query = ref.watch(inventorySearchProvider).trim().toLowerCase();
  final DateTime now = DateTime.now();

  return items.where((Item item) {
    if (!filter.matches(item, now: now)) return false;

    if (query.isEmpty) return true;

    // Title, SKU and barcode — the three things a seller has to hand when
    // looking for a specific item (plan §21). Notes are deliberately not
    // searched: they are long, and matching them makes the results look
    // random to someone who typed a SKU.
    return item.title.toLowerCase().contains(query) ||
        (item.sku?.toLowerCase().contains(query) ?? false) ||
        (item.barcode?.toLowerCase().contains(query) ?? false);
  }).toList();
});
