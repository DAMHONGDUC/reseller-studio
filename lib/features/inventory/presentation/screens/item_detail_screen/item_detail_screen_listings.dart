part of 'item_detail_screen.dart';

/// Every marketplace this item is live on, and what each is asking (plan §13).
///
/// **Edit opens Marketplaces management; it does not open fields here** —
/// owner's rule, and it reverses the inline reprice this section used to do.
/// One screen already prices every platform an item is on and is the only one
/// that can add another, so a second set of boxes here was the same number
/// written two ways — and the half a seller reached first could not do the
/// thing they usually came for.
///
/// **It adds no marketplace either.** This section reports; the button hands
/// the whole question over.
class _ListingsSection extends ConsumerWidget {
  const _ListingsSection({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Listing> listings =
        ref.watch(listingsForItemProvider(item.id)).value ?? const <Listing>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdSectionHeaderV3(
          title: context.l10n.itemListings,
          // Nothing to reprice, so no Edit: the way onto a first marketplace
          // is the actions sheet, which names it.
          action: listings.isEmpty
              ? null
              : SdButtonV3(
                  variant: SdButtonVariantV3.text,
                  label: context.l10n.actionEdit,
                  icon: AppIconConstant.edit,
                  size: SdButtonSizeV3.small,
                  onPressed: () => context.push(AppRoutes.crossList(item.id)),
                ),
        ),
        SdCardV3(
          child: listings.isEmpty
              ? Text(
                  context.l10n.itemNotListed,
                  style: context.textTheme3.bodyMedium!.muted3(context),
                )
              : _ListingFacts(listings: listings),
        ),
      ],
    );
  }
}

/// The rows as they read on the detail screen.
class _ListingFacts extends StatelessWidget {
  const _ListingFacts({required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      for (int i = 0; i < listings.length; i++) ...<Widget>[
        _ListingRow(listing: listings[i]),
        if (i != listings.length - 1) const SdDividerV3(),
      ],
    ],
  );
}
