part of 'inventory_screen.dart';

/// The Filters chip first, then the Show preset, then one chip per group of
/// the sheet — each opening that group alone (`docs/rules/SCREENS.md`).
class _FilterStrip extends ConsumerWidget {
  const _FilterStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ItemFilterCriteria criteria = ref.watch(inventoryCriteriaProvider);
    final InventoryFilter tab = ref.watch(inventoryFilterProvider);

    return AppFilterStrip(
      children: <Widget>[
        SdFilterChipV3(
          icon: AppIconConstant.tune,
          label: context.l10n.filterTitle,
          selected: ref.watch(inventoryActiveFilterCountProvider) > 0,
          onSelected: () => InventoryFilterSheet.show(context),
        ),
        SdFilterChipV3(
          label: context.l10n.filterShow,
          opensSheet: true,
          selected: tab != InventoryFilter.all,
          onSelected: () => InventoryFilterSheet.showPreset(context),
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

/// Pins the filter strip under the docked search header.
///
/// **Owner's rule: Inventory's chips stay put while the list scrolls, the way
/// Orders' do.** Orders gets it for free — its strip sits in a `Column` above
/// an `Expanded` list, so it is never inside the scrollable. Inventory's list
/// *is* the scrollable, because `SdSearchHeaderV3` has to live in it to dock,
/// so the strip has to be a pinned sliver to stay.
///
/// **Still not part of the app bar** (owner's rule, `DESIGN_SYSTEM.md`): it is
/// its own sliver in the body with the body's own background, below the
/// chrome rather than inside it.
class _PinnedFilterStrip extends SliverPersistentHeaderDelegate {
  const _PinnedFilterStrip({required this.showActiveFilters});

  /// Whether the band carries the count-and-reset row — it is only there when
  /// something is filtered, so the extent has to move with it.
  final bool showActiveFilters;

  /// The gap between the chips and the row under them. Not `topGap`: that gap
  /// belongs to the boundary between the band and the screen, and this one is
  /// inside the band.
  static double get _rowGap => SdSpacingConstant.h8;

  /// The strip and the gap either side of it — the band the screen owns.
  /// Fixed, because a pinned sliver states its extent before it lays anything
  /// out.
  double get _extent =>
      SdContentPaddingV3.topGap * 2 +
      AppFilterStrip.height +
      (showActiveFilters ? _rowGap + AppActiveFilterBar.height : 0);

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    // Opaque, or the list scrolls visibly through the pinned band.
    color: context.sdTheme3.background,
    child: Column(
      children: <Widget>[
        SizedBox(height: SdContentPaddingV3.topGap),
        const _FilterStrip(),
        if (showActiveFilters) ...<Widget>[
          SizedBox(height: _rowGap),
          const _ActiveFilters(),
        ],
        SizedBox(height: SdContentPaddingV3.topGap),
      ],
    ),
  );

  @override
  bool shouldRebuild(covariant _PinnedFilterStrip oldDelegate) =>
      oldDelegate.showActiveFilters != showActiveFilters;
}
