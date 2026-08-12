import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../domain/entities/item.dart';
import '../../../providers.dart';
import '../../widgets/item_card.dart';

/// Inventory — "what do I have?".
///
/// The five tabs are fixed by the plan (§7): `All | Listed | Reserved | Sold |
/// Stale`. Each carries its count, because a seller scanning the strip decides
/// where to tap from the number — which is why `SdFilterChipV3` renders the
/// count inside the chip rather than beside it.
///
/// **All five counts come from one stream**, folded in
/// `inventoryCountsProvider`. Per-tab queries would mean five live listeners
/// for one screen, and the counts could disagree with the list being shown.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Item> items = ref.watch(visibleItemsProvider);
    final AsyncValue<List<Item>> source = ref.watch(itemsProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: 'Inventory',
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Symbols.qr_code_scanner_rounded),
            tooltip: 'Scan',
          ),
          SizedBox(width: SdSpacingConstant.w8),
        ],
      ),
      // Lifted clear of the floating tab bar. `extendBody` keeps the FAB in
      // the body's coordinate space rather than stacking it above the bottom
      // slot, so without this the button renders *behind* the glass — which
      // looks like a bug and makes it hard to tap.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: SdContentPaddingV3.floatingBarInset(context),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Symbols.add_rounded),
          label: const Text('Quick Add'),
        ),
      ),
      body: Column(
        children: <Widget>[
          const _SearchField(),
          const _FilterStrip(),
          Expanded(
            child: switch (source) {
              // A screen that has not loaded is not empty — saying "No items"
              // to a seller with four hundred is worse than a spinner.
              AsyncLoading<List<Item>>() when !source.hasValue =>
                const SdLoadingV3Page(),
              AsyncError<List<Item>>() => const SdEmptyStateV3(
                icon: Symbols.error_rounded,
                title: 'Could not load inventory',
                message: 'Please try again.',
              ),
              _ when items.isEmpty => _EmptyInventory(
                hasAnyItems: (source.value ?? const <Item>[]).isNotEmpty,
              ),
              _ => _ItemList(items: items),
            },
          ),
        ],
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    // One `now` for the whole list, so every row agrees on what stale means.
    final DateTime now = DateTime.now();

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.topGap,
        SdContentPaddingV3.horizontal,
        // Clears the floating tab bar AND the FAB stacked above it —
        // otherwise the last row sits under "Quick Add" and cannot be tapped.
        SdContentPaddingV3.bottom(context, floatingNav: true) +
            SdSpacingConstant.h64,
      ),
      itemCount: items.length,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: SdContentPaddingV3.listItemGap),
      itemBuilder: (BuildContext context, int index) {
        final Item item = items[index];

        return ItemCard(
          item: item,
          now: now,
          onTap: () => context.push(AppRoutes.item(item.id)),
        );
      },
    );
  }
}

/// Distinguishes "no inventory at all" from "nothing matches this filter".
///
/// The same layout would otherwise tell a seller with four hundred items that
/// they have none, just because the Stale tab happens to be clear — which is
/// good news being reported as an empty screen.
class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.hasAnyItems});

  final bool hasAnyItems;

  @override
  Widget build(BuildContext context) => hasAnyItems
      ? const SdEmptyStateV3(
          icon: Symbols.filter_alt_off_rounded,
          title: 'Nothing here',
          message: 'No items match this filter.',
        )
      : const SdEmptyStateV3(
          icon: Symbols.inventory_2_rounded,
          title: 'No items yet',
          message: 'Add your first item to start tracking inventory.',
        );
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      SdContentPaddingV3.horizontal,
      SdContentPaddingV3.topGap,
      SdContentPaddingV3.horizontal,
      0,
    ),
    child: SdSearchFieldV3(
      controller: _controller,
      hint: 'Title, SKU or barcode',
      clearTooltip: 'Clear search',
      onChanged: (String value) =>
          ref.read(inventorySearchProvider.notifier).update(value),
    ),
  );
}

class _FilterStrip extends ConsumerWidget {
  const _FilterStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryFilter selected = ref.watch(inventoryFilterProvider);
    final Map<InventoryFilter, int> counts = ref.watch(inventoryCountsProvider);

    return SizedBox(
      height: SdSpacingConstant.h56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV3.horizontal,
          vertical: SdSpacingConstant.h8,
        ),
        itemCount: InventoryFilter.values.length,
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(width: SdSpacingConstant.w8),
        itemBuilder: (BuildContext context, int index) {
          final InventoryFilter filter = InventoryFilter.values[index];

          return SdFilterChipV3(
            label: filter.label,
            count: counts[filter],
            selected: filter == selected,
            onSelected: () =>
                ref.read(inventoryFilterProvider.notifier).select(filter),
          );
        },
      ),
    );
  }
}
