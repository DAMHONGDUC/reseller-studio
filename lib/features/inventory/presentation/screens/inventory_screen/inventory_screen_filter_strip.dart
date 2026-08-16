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
  const _PinnedFilterStrip();

  /// The strip and the gap either side of it — the band the screen owns.
  /// Fixed, because a pinned sliver states its extent before it lays anything
  /// out.
  static double get _extent =>
      SdContentPaddingV3.topGap * 2 + AppFilterStrip.height;

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
        SizedBox(height: SdContentPaddingV3.topGap),
      ],
    ),
  );

  @override
  bool shouldRebuild(covariant _PinnedFilterStrip oldDelegate) => false;
}
