part of 'item_card.dart';

/// The one move this row is asking for, as a button on the card itself.
///
/// - stale stock gets **Reprice**: a price is what usually stops it moving
/// - stock on the shelf and listed nowhere gets **List on…**, the same
///   cross-list screen the marketplace arrow opens
///
/// Nothing for any other row, and nothing while a selection is open — every
/// tap ticks a row then. At most one button: two would be a menu, and the
/// menu is the ⋮ beside the title.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.item,
    required this.now,
    required this.listings,
    this.onReprice,
    this.onMarketPrices,
  });

  final Item item;
  final DateTime now;
  final List<Listing> listings;
  final VoidCallback? onReprice;
  final VoidCallback? onMarketPrices;

  /// Whether a card with these facts draws a button at all.
  static bool shows({
    required Item item,
    required DateTime now,
    required List<Listing> listings,
    required VoidCallback? onReprice,
    required VoidCallback? onMarketPrices,
  }) =>
      (onReprice != null && _StateBadges.isStale(item, now)) ||
      (onMarketPrices != null && _isUnlisted(item, listings));

  static bool _isUnlisted(Item item, List<Listing> listings) =>
      item.status == ItemStatus.inStock &&
      ListingMarketplaces.of(listings).isEmpty;

  @override
  Widget build(BuildContext context) {
    final bool reprice = onReprice != null && _StateBadges.isStale(item, now);

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SdButtonV3(
        variant: SdButtonVariantV3.secondary,
        size: SdButtonSizeV3.small,
        icon: reprice ? AppIconConstant.priceChange : AppIconConstant.sell,
        label: reprice
            ? context.l10n.itemActionReprice
            : context.l10n.itemActionList,
        onPressed: reprice ? onReprice : onMarketPrices,
      ),
    );
  }
}
