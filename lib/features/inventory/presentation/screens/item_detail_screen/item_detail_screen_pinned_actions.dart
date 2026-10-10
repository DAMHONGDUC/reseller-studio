part of 'item_detail_screen.dart';

/// Mark as sold and Reprice, holding the bottom edge in the thumb zone.
///
/// **The two verbs a seller opens an item for**, pinned the way the order
/// detail pins its next move; everything else stays in the Actions sheet,
/// which still lists both. Only on stock still on hand — a sold or archived
/// item has no next move, and a bar holding one would invite a mistake.
class _PinnedActions extends ConsumerWidget {
  const _PinnedActions({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppPinnedAction(
    label: context.l10n.itemActionMarkSold,
    icon: AppIconConstant.payments,
    onPressed: () => ItemQuickActions.markSold(context, ref, item),
    secondary: SdButtonV3(
      variant: SdButtonVariantV3.outlined,
      label: context.l10n.itemActionReprice,
      icon: AppIconConstant.priceChange,
      expand: true,
      onPressed: () => ItemQuickActions.reprice(context, ref, item),
    ),
  );
}
