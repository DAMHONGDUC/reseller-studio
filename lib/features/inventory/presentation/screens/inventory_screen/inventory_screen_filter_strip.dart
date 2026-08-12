part of 'inventory_screen.dart';

class _FilterStrip extends ConsumerWidget {
  const _FilterStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryFilter selected = ref.watch(inventoryFilterProvider);
    final Map<InventoryFilter, int> counts = ref.watch(inventoryCountsProvider);

    // Its own height, because a horizontal list has none of its own and the
    // body has no slot to give it one.
    return SizedBox(
      height: SdContentPaddingV3.filterStrip,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV3.horizontal,
          vertical: SdContentPaddingV3.filterStripGap,
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
