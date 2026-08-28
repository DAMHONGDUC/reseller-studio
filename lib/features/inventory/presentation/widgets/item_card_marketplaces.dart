part of 'item_card.dart';

/// Which marketplaces this item is live on.
///
/// **Names, not prices** — owner's rule. A per-platform figure on the row was
/// a number nobody acts on while scanning; what the list is read for is
/// *where* the item is. The prices stay one tap away on the detail screen.
///
/// **Every marketplace shows, wrapped rather than cut to one line.** A list
/// that ellipsized hid exactly the platform the seller was looking for.
class _Marketplaces extends StatelessWidget {
  const _Marketplaces({required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    // Walked in enum order rather than listing order: two listings on one
    // platform read as one badge, and the row cannot reshuffle between builds.
    final List<Marketplace> marketplaces = Marketplace.values
        .where(
          (Marketplace marketplace) => listings.any(
            (Listing listing) => listing.marketplace == marketplace,
          ),
        )
        .toList();

    if (marketplaces.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: SdSpacingConstant.h8),
      child: Wrap(
        spacing: SdSpacingConstant.w6,
        runSpacing: SdSpacingConstant.h4,
        children: <Widget>[
          for (final Marketplace marketplace in marketplaces)
            SdBadgeV3(label: marketplace.displayName),
        ],
      ),
    );
  }
}
