part of 'item_detail_screen.dart';

/// The last moves of this item's listing prices, and why each happened.
///
/// **It owns its header and is absent with no history** — a heading over
/// nothing is the gap `lib/features/home/CLAUDE.md` warns about.
class _PriceHistorySection extends ConsumerWidget {
  const _PriceHistorySection({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ListingPriceChange> changes =
        ref.watch(priceChangesForItemProvider(item.id)).value ??
        const <ListingPriceChange>[];
    final Map<String, String> names = <String, String>{
      for (final Listing listing
          in ref.watch(listingsForItemProvider(item.id)).value ??
              const <Listing>[])
        listing.id: listing.marketplaceName,
    };
    final List<ListingPriceChange> shown = changes
        .take(ItemDetailConstant.priceHistoryRows)
        .toList();

    if (shown.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: SdContentPaddingV3.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdSectionHeaderV3(title: context.l10n.itemPriceHistory),
          SdCardV3(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < shown.length; i++) ...<Widget>[
                  _PriceChangeRow(
                    change: shown[i],
                    marketplace: names[shown[i].listingId],
                  ),
                  if (i != shown.length - 1) const SdDividerV3(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceChangeRow extends StatelessWidget {
  const _PriceChangeRow({required this.change, required this.marketplace});

  final ListingPriceChange change;
  final String? marketplace;

  @override
  Widget build(BuildContext context) => Padding(
    padding: SdContentPaddingV3.rowNoGutter,
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                marketplace ?? '—',
                style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
              SizedBox(height: SdSpacingConstant.h4),
              Text(
                '${change.reason.label(context)} · '
                '${DateTimeUtils.mediumDate(change.changedAt, locale: context.localeTag)}',
                style: context.textTheme3.bodySmall!.muted3(context),
              ),
            ],
          ),
        ),
        Text(
          '${context.money(change.from)} → ${context.money(change.to)}',
          style: context.textTheme3.bodyMedium!.tabular3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
      ],
    ),
  );
}
