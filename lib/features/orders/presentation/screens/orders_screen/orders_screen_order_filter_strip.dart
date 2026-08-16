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
