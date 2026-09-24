part of 'item_detail_screen.dart';

/// Every marketplace this item is live on, and what each is asking (plan §13).
///
/// **It sits directly under Price** — owner's rule. The cost and the floor are
/// half of one question, and what each platform is asking is the other half;
/// a seller reading the money on this screen reads it in one run rather than
/// scrolling past where the item came from to reach it.
///
/// **Edit opens Marketplaces management; it does not open fields here** —
/// owner's rule, and it reverses the inline reprice this section used to do.
/// One screen already prices every platform an item is on and is the only one
/// that can add another, so a second set of boxes here was the same number
/// written two ways — and the half a seller reached first could not do the
/// thing they usually came for.
///
/// **The Edit is there whether or not the item is listed** — owner's rule,
/// and it is now the only way onto a first marketplace: the actions sheet no
/// longer names one. An item on nothing showed the line saying so and no way
/// to change it, which made the section a report of a state the seller could
/// not leave.
class _ListingsSection extends ConsumerWidget {
  const _ListingsSection({required this.item});

  final Item item;

  /// Opens Marketplaces management, or says what the item is missing.
  ///
  /// The gate came with the row this button replaced: an item that has sold
  /// or been archived has left inventory, and putting it back on a platform
  /// is the move `crossListCheck` exists to refuse.
  void _edit(BuildContext context, WidgetRef ref) {
    final ItemTransitionCheck check = ref
        .read(itemActionsControllerProvider.notifier)
        .crossListCheck(item);

    if (!check.isAllowed) {
      SdSnackBarUtilsV3.error(
        context,
        ItemBlockPresenter.messages(context, check.blocks),
      );

      return;
    }

    context.push(AppRoutes.crossList(item.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Listing> listings =
        ref.watch(listingsForItemProvider(item.id)).value ?? const <Listing>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SdSectionHeaderV3(
          title: context.l10n.itemListings,
          action: SdButtonV3(
            variant: SdButtonVariantV3.text,
            label: context.l10n.actionEdit,
            icon: AppIconConstant.edit,
            size: SdButtonSizeV3.small,
            onPressed: () => _edit(context, ref),
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
