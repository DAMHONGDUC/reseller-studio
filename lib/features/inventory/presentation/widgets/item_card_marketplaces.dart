part of 'item_card.dart';

/// How many marketplaces this item is live on.
///
/// **One count, no names or prices** — owner's rule. The detail screen owns
/// the full list; the card stays compact while answering distribution.
class _Marketplaces extends StatelessWidget {
  const _Marketplaces({required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    final int count = listings
        .map((Listing listing) => listing.marketplace)
        .toSet()
        .length;

    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: SdSpacingConstant.h8),
      child: _ReadOnlyTag(
        label: context.l10n.inventoryMarketCount(count),
        color: context.sdTheme3.info,
        icon: AppIconConstant.storefront,
      ),
    );
  }
}
