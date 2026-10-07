part of 'scan_result_screen.dart';

/// The item the code belongs to, and what a seller holding it usually does
/// next: sell it, reprice it, or open it. Everything else is one row away in
/// the same actions sheet the inventory list uses.
class _ItemResult extends ConsumerWidget {
  const _ItemResult({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = ref.watch(clockProvider).now();
    final Duration staleThreshold = ref.watch(staleThresholdProvider);
    final List<Listing> listings =
        ref.watch(listingsForItemProvider(item.id)).value ?? const <Listing>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: SdSpacingConstant.h12),
        ItemCard(
          item: item,
          listings: listings,
          now: now,
          staleThreshold: staleThreshold,
          onTap: () => context.push(AppRoutes.item(item.id)),
        ),
        AppSection.rows(
          title: context.l10n.scanResultActions,
          children: <Widget>[
            AppListRow(
              icon: AppIconConstant.payments,
              title: context.l10n.itemActionMarkSold,
              onTap: () => ItemQuickActions.markSold(context, ref, item),
            ),
            AppListRow(
              icon: AppIconConstant.priceChange,
              title: context.l10n.itemActionReprice,
              onTap: () => ItemQuickActions.reprice(context, ref, item),
            ),
            AppListRow(
              icon: AppIconConstant.edit,
              title: context.l10n.scanResultOpenItem,
              onTap: () => context.push(AppRoutes.item(item.id)),
            ),
            AppListRow(
              icon: AppIconConstant.moreVert,
              title: context.l10n.scanResultMoreActions,
              onTap: () => ItemActionsSheet.show(context, item),
            ),
          ],
        ),
      ],
    );
  }
}
