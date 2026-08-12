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
      ? const SdEmptyStateV3(
          icon: Symbols.filter_alt_off_rounded,
          title: 'Nothing here',
          message: 'No items match this filter.',
        )
      : const SdEmptyStateV3(
          icon: Symbols.inventory_2_rounded,
          title: 'No items yet',
          message: 'Add your first item to start tracking inventory.',
        );
}
