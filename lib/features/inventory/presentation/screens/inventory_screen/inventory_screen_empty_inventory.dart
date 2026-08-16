part of 'inventory_screen.dart';

/// Distinguishes "no inventory at all" from "nothing matches this filter".
///
/// The same layout would otherwise tell a seller with four hundred items that
/// they have none, just because the Stale tab happens to be clear — which is
/// good news being reported as an empty screen.
class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.hasAnyItems});

  final bool hasAnyItems;

  @override
  Widget build(BuildContext context) => hasAnyItems
      ? SdEmptyStateV3(
          icon: Symbols.filter_alt_off_rounded,
          title: context.l10n.commonNothingHere,
          message: context.l10n.inventoryNoMatch,
        )
      : SdEmptyStateV3(
          icon: Symbols.inventory_2_rounded,
          title: context.l10n.inventoryEmptyTitle,
          message: context.l10n.inventoryEmptyBody,
        );
}
