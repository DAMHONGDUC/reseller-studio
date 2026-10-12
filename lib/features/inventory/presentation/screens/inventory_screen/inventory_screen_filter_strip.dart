part of 'inventory_screen.dart';

/// The Filters chip first, then one chip per group of the sheet — each opening that group alone (`docs/rules/SCREENS.md`).
class _FilterStrip extends ConsumerWidget {
  const _FilterStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ItemFilterCriteria criteria = ref.watch(inventoryCriteriaProvider);

    return AppFilterStrip(
      children: <Widget>[
        SdFilterChipV3(
          icon: AppIconConstant.tune,
          label: context.l10n.filterTitle,
          selected: ref.watch(inventoryActiveFilterCountProvider) > 0,
          onSelected: () => InventoryFilterSheet.show(context),
        ),
        for (final ItemFilterGroup group in ItemFilterGroup.values)
          SdFilterChipV3(
            label: group.label(context),
            opensSheet: true,
            selected: criteria.narrows(group),
            onSelected: () => InventoryFilterSheet.showGroup(context, group),
          ),
      ],
    );
  }
}

/// The count-and-reset line under the strip.
///
/// Its own consumer so a chip tap rebuilds this row and not the pinned band
/// around it.
class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppActiveFilterBar(
    count: ref.watch(inventoryActiveFilterCountProvider),
    onReset: ref.read(inventoryCriteriaProvider.notifier).reset,
  );
}
