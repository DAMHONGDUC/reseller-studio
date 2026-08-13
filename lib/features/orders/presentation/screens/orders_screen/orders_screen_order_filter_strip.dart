part of 'orders_screen.dart';

class _OrderFilterStrip extends ConsumerWidget {
  const _OrderFilterStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OrderFilter selected = ref.watch(orderFilterProvider);
    final Map<OrderFilter, int> counts = ref.watch(orderCountsProvider);

    return SizedBox(
      height: SdContentPaddingV3.filterStrip,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV3.horizontal,
          vertical: SdContentPaddingV3.filterStripGap,
        ),
        itemCount: OrderFilter.values.length,
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(width: SdSpacingConstant.w8),
        itemBuilder: (BuildContext context, int index) {
          final OrderFilter filter = OrderFilter.values[index];

          return SdFilterChipV3(
            label: OrderFilterLabel.of(context, filter),
            count: counts[filter],
            selected: filter == selected,
            onSelected: () =>
                ref.read(orderFilterProvider.notifier).select(filter),
          );
        },
      ),
    );
  }
}
