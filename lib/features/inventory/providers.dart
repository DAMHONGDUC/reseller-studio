/// Riverpod wiring for `inventory`. Other features import this file, never
/// anything under `inventory/data/` or `inventory/presentation/`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../mock_data/providers.dart';
import '../pricing/domain/services/profit_calculator.dart';
import 'domain/entities/item.dart';
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
