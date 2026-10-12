part of 'orders_screen.dart';

/// The Filters chip first, then one chip per group of the sheet — each opening that group alone (`docs/rules/SCREENS.md`).
class _OrderFilterStrip extends ConsumerWidget {
  const _OrderFilterStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OrderFilterCriteria criteria = ref.watch(orderCriteriaProvider);

    return AppFilterStrip(
      children: <Widget>[
        SdFilterChipV3(
          icon: AppIconConstant.tune,
          label: context.l10n.filterTitle,
          selected: ref.watch(orderActiveFilterCountProvider) > 0,
          onSelected: () => OrderFilterSheet.show(context),
        ),
        for (final OrderFilterGroup group in OrderFilterGroup.values)
          SdFilterChipV3(
            label: group.label(context),
            opensSheet: true,
            selected: criteria.narrows(group),
            onSelected: () => OrderFilterSheet.showGroup(context, group),
          ),
      ],
    );
  }
}

/// The count-and-reset line under the strip. The pinned band decides when it
/// shows, and owns the gap above it.
class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppActiveFilterBar(
      count: ref.watch(orderActiveFilterCountProvider),
      onReset: ref.read(orderCriteriaProvider.notifier).reset,
    );
  }
}
