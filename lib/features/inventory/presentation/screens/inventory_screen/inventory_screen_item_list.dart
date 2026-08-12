part of 'inventory_screen.dart';

class _ItemList extends ConsumerWidget {
  const _ItemList({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One `now` for the whole list, so every row agrees on what stale means.
    final DateTime now = DateTime.now();
    final Set<String> selected = ref.watch(inventorySelectionProvider);
    final bool isSelecting = selected.isNotEmpty;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        0,
        SdContentPaddingV3.horizontal,
        // Clears the floating tab bar AND the FAB stacked above it —
        // otherwise the last row sits under "Quick Add" and cannot be tapped.
        SdContentPaddingV3.bottom(context, floatingNav: true) + SdFabV3.size,
      ),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(height: SdContentPaddingV3.listItemGap),
        itemBuilder: (BuildContext context, int index) {
          final Item item = items[index];

          return ItemCard(
            item: item,
            now: now,
            isSelecting: isSelecting,
            isSelected: selected.contains(item.id),
            // While a selection is open a tap ticks rather than opens: a
            // seller mid-bulk-edit who lands on a detail screen has lost the
            // forty rows they had just picked.
            onTap: isSelecting
                ? () =>
                      ref
                          .read(inventorySelectionProvider.notifier)
                          .toggle(item.id)
                : () => context.push(AppRoutes.item(item.id)),
            onLongPress: () =>
                ref.read(inventorySelectionProvider.notifier).toggle(item.id),
          );
        },
      ),
    );
  }
}
