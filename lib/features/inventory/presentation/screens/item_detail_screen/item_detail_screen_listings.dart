part of 'item_detail_screen.dart';

/// Every marketplace this item is live on — the cross-listing view from the
/// item's side (plan §13).
class _Listings extends ConsumerWidget {
  const _Listings({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Listing> listings =
        ref.watch(listingsForItemProvider(itemId)).value ?? const <Listing>[];

    if (listings.isEmpty) {
      return SdCardV3(
        child: Text(
          context.l10n.itemNotListed,
          style: context.textTheme3.bodyMedium!.muted3(context),
        ),
      );
    }

    return SdCardV3(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < listings.length; i++) ...<Widget>[
            _ListingRow(listing: listings[i]),
            if (i != listings.length - 1)
              const SdDividerV3(),
          ],
        ],
      ),
    );
  }
}
