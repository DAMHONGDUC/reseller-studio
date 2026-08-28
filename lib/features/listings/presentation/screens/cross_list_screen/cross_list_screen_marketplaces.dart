part of 'cross_list_screen.dart';

/// Where to put it. **The platforms the item is already on are shown and
/// disabled, never hidden**: "already on eBay" is the answer to the question
/// the seller came with, and a missing row reads as a missing marketplace.
class _Marketplaces extends ConsumerWidget {
  const _Marketplaces({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<Marketplace> already = <Marketplace>{
      for (final Listing listing
          in ref.watch(listingsForItemProvider(itemId)).value ??
              const <Listing>[])
        listing.marketplace,
    };
    final Set<Marketplace> selected = ref
        .watch(crossListControllerProvider)
        .selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.crossListPickMarketplaces,
          style: context.textTheme3.labelLarge!.copyWith(
            color: context.sdTheme3.textSecondary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h8),
        SdCardV3(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < Marketplace.values.length; i++) ...<Widget>[
                _MarketplaceRow(
                  marketplace: Marketplace.values[i],
                  isSelected: selected.contains(Marketplace.values[i]),
                  isAlreadyListed: already.contains(Marketplace.values[i]),
                ),
                if (i != Marketplace.values.length - 1) const SdDividerV3(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MarketplaceRow extends ConsumerWidget {
  const _MarketplaceRow({
    required this.marketplace,
    required this.isSelected,
    required this.isAlreadyListed,
  });

  final Marketplace marketplace;
  final bool isSelected;
  final bool isAlreadyListed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: isAlreadyListed
          ? null
          : () => ref
                .read(crossListControllerProvider.notifier)
                .toggle(marketplace),
      child: Padding(
        padding: SdContentPaddingV3.row,
        child: Row(
          children: <Widget>[
            SdIconV3(
              isSelected
                  ? Symbols.check_circle_rounded
                  : Symbols.radio_button_unchecked_rounded,
              fill: isSelected ? 1 : 0,
              color: isSelected
                  ? context.colorScheme3.primary
                  : context.sdTheme3.textSecondary,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Text(
                marketplace.displayName,
                style: context.textTheme3.bodyMedium!.copyWith(
                  color: isAlreadyListed
                      ? context.sdTheme3.textSecondary
                      : context.sdTheme3.textPrimary,
                ),
              ),
            ),
            if (isAlreadyListed)
              SdBadgeV3(label: context.l10n.crossListAlreadyListed),
          ],
        ),
      ),
    );
  }
}
