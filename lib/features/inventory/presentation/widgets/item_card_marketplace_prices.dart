part of 'item_card.dart';

/// What this item is listed at, on each marketplace it is live on.
///
/// **The card answers "what is this priced at" completely** — owner's rule.
/// Asking price is what the seller wants for the thing; these are what buyers
/// actually see, and they can differ on every platform. A card that showed
/// only the first left the seller opening the item to find out whether the
/// eBay price had been cut.
///
/// **One line, ellipsized, and absent when there is nothing to say.** A row of
/// per-platform figures is a footnote to the price line above it, not a second
/// price line — an item on five marketplaces must not make its card twice as
/// tall as one on none.
class _MarketplacePrices extends StatelessWidget {
  const _MarketplacePrices({required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) return const SizedBox.shrink();

    final String line = listings
        .map(
          (Listing listing) => context.l10n.itemMarketplacePriceEntry(
            listing.marketplace.displayName,
            context.money(listing.price),
          ),
        )
        .join(' · ');

    return Padding(
      padding: EdgeInsets.only(top: SdSpacingConstant.h6),
      child: Text(
        line,
        style: context.textTheme3.bodySmall!.tabular3.faint3(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
