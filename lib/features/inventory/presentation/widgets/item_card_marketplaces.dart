part of 'item_card.dart';

/// Where the item stands on the marketplaces: how many carry it, or that none
/// do.
///
/// **One count, no names or prices** — owner's rule. The detail screen owns
/// the full list; the card stays compact while answering distribution.
///
/// **An item nobody has listed says so, in red** — owner's rule. Nothing read
/// as "no marketplaces worth naming" when the truth was stock earning
/// nothing, which is the one thing on this card a seller can fix today.
class _Marketplaces extends StatelessWidget {
  const _Marketplaces({required this.count});

  /// Distinct marketplaces carrying the item. Zero is the unlisted case, and
  /// the caller has already decided that saying so is worth a tag.
  final int count;

  @override
  Widget build(BuildContext context) => count == 0
      ? _DisplayTag(
          label: context.l10n.inventoryNotListed,
          color: context.sdTheme3.danger,
          icon: AppIconConstant.storefront,
        )
      : _DisplayTag(
          label: context.l10n.inventoryMarketCount(count),
          color: context.sdTheme3.textSecondary,
          icon: AppIconConstant.storefront,
        );
}
