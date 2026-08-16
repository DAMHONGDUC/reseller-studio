part of 'inventory_screen.dart';

class _FilterStrip extends ConsumerWidget {
  const _FilterStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryFilter selected = ref.watch(inventoryFilterProvider);
    final Map<InventoryFilter, int> counts = ref.watch(inventoryCountsProvider);

    return AppFilterStrip(
      children: <Widget>[
        for (final InventoryFilter filter in InventoryFilter.values)
          SdFilterChipV3(
            label: filter.label,
            count: counts[filter],
            selected: filter == selected,
            onSelected: () =>
                ref.read(inventoryFilterProvider.notifier).select(filter),
          ),
      ],
    );
  }
}
