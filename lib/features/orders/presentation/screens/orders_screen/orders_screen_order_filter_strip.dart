part of 'orders_screen.dart';

class _OrderFilterStrip extends ConsumerWidget {
  const _OrderFilterStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OrderFilter selected = ref.watch(orderFilterProvider);
    final Map<OrderFilter, int> counts = ref.watch(orderCountsProvider);

    return AppFilterStrip(
      children: <Widget>[
        for (final OrderFilter filter in OrderFilter.values)
          SdFilterChipV3(
            label: OrderFilterLabel.of(context, filter),
            count: counts[filter],
            selected: filter == selected,
            onSelected: () =>
                ref.read(orderFilterProvider.notifier).select(filter),
          ),
      ],
    );
  }
}

/// The count-and-reset line under the strip, and the gap above it.
///
/// It renders nothing at all when nothing is filtered, so the screen stacks it
/// unconditionally rather than asking the question twice.
class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(orderActiveFilterCountProvider);

    if (count == 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(height: SdSpacingConstant.h8),
        AppActiveFilterBar(
          count: count,
          onReset: ref.read(orderCriteriaProvider.notifier).reset,
        ),
      ],
    );
  }
}
