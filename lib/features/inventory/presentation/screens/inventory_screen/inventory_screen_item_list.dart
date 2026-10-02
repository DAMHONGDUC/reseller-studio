part of 'inventory_screen.dart';

class _ItemList extends ConsumerWidget {
  const _ItemList({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One `now` for the whole list, so every row agrees on what stale means.
    final DateTime now = ref.watch(clockProvider).now();
    // Grouped once here rather than watched per card: a family subscription
    // on every row rebuilds the whole list on any listing write.
    final Map<String, List<Listing>> listings = ListingsByItem.group(
      ref.watch(listingsProvider).value ?? const <Listing>[],
    );
    final Set<String> selected = ref.watch(inventorySelectionProvider);
    final bool isSelecting = selected.isNotEmpty;

    return SliverPadding(
      // The gutter is the screen's now — one for every sliver below the
      // chrome. What is left here is the clearance only this list needs:
      // the floating tab bar AND the FAB stacked above it, or the last row
      // sits under "Quick Add" and cannot be tapped. The same arithmetic
      // every other create screen uses, rather than a second copy of it: this
      // list is a sliver, so it takes the number instead of the `EdgeInsets`.
      padding: EdgeInsets.only(
        bottom: AppAddFabScaffold.listPadding(
          context,
          floatingNav: true,
        ).bottom,
      ),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(height: SdContentPaddingV3.listItemGap),
        itemBuilder: (BuildContext context, int index) {
          final Item item = items[index];

          return ItemCard(
            item: item,
            listings: listings[item.id] ?? const <Listing>[],
            now: now,
            isSelecting: isSelecting,
            isSelected: selected.contains(item.id),
            // While a selection is open a tap ticks rather than opens: a
            // seller mid-bulk-edit who lands on a detail screen has lost the
            // forty rows they had just picked.
            onTap: isSelecting
                ? () => ref
                      .read(inventorySelectionProvider.notifier)
                      .toggle(item.id)
                : () => context.push(AppRoutes.item(item.id)),
            onLongPress: () =>
                ref.read(inventorySelectionProvider.notifier).toggle(item.id),
            // The same sheet the detail screen opens — one list of verbs, so
            // an action added there cannot go missing here.
            onActions: () => ItemActionsSheet.show(context, item),
            // The row shows no price per marketplace; this is where they are.
            onMarketPrices: () => context.push(AppRoutes.crossList(item.id)),
            onReprice: () => ItemQuickActions.reprice(context, ref, item),
          );
        },
      ),
    );
  }
}
