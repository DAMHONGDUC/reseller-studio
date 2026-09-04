part of 'record_sale_screen.dart';

/// The rows to pick from.
///
/// **`AppListRow`, not the inventory card.** This is a chooser, the same job
/// the Search screen does with the same widget — the card belongs to the
/// screens that own the records, and reaching into Inventory's presentation
/// layer for it is what the dependency rule forbids.
class _SaleItemList extends ConsumerWidget {
  const _SaleItemList({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read once for the whole list, never per row: a family watch on every
    // row is one subscription each and a rebuild storm on any listing write.
    final List<Listing> listings =
        ref.watch(listingsProvider).value ?? const <Listing>[];
    final Set<String> selected = ref.watch(recordSaleSelectionProvider);

    return ListView(
      padding: SdContentPaddingV3.screen(context),
      children: <Widget>[
        AppListCard(
          children: items
              .map(
                (Item item) => _SaleItemRow(
                  item: item,
                  isSelected: selected.contains(item.id),
                  isSelecting: selected.isNotEmpty,
                  marketplaceCount: ListingMarketplaces.countFor(
                    listings,
                    item.id,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

/// One item to sell.
///
/// **No price on the row, a marketplace count and the expected price
/// instead** — owner's rule. What it is live at is a different number on every
/// platform, and the one this row used to print was the highest of them: a
/// figure the seller was about to be asked to confirm and would rarely see
/// again. What decides which row to tap is where the thing is listed and what
/// the seller wanted for it.
class _SaleItemRow extends ConsumerWidget {
  const _SaleItemRow({
    required this.item,
    required this.marketplaceCount,
    required this.isSelected,
    required this.isSelecting,
  });

  final Item item;

  /// Whether this row is part of the bundle being built.
  final bool isSelected;

  /// Whether a bundle is being built at all. Once it is, a tap adds and
  /// removes rather than opening the sheet — otherwise the seller's second
  /// tap would sell one item instead of joining it to the others.
  final bool isSelecting;

  /// Distinct marketplaces carrying it — zero for an item on none, which is
  /// a fact rather than a missing figure.
  final int marketplaceCount;

  /// Where it is, what it is called on the shelf, and how many platforms
  /// carry it. The SKU earns its place because two items can carry the same
  /// title and only one of them sold.
  String _subtitle(BuildContext context) => <String>[
    item.status.label(context),
    ?item.sku,
    marketplaceCount == 0
        ? context.l10n.inventoryNotListed
        : context.l10n.inventoryMarketCount(marketplaceCount),
  ].join(' · ');

  /// Picking an item opens the sheet; a recorded sale closes this screen so
  /// the seller lands back on Orders with the new order under them.
  Future<void> _pick(BuildContext context) async {
    final bool? recorded = await MarkSoldSheet.show(context, <Item>[item]);

    if (!context.mounted || !(recorded ?? false)) return;

    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // **Shown, not hidden** — owner's rule. The same check the actions sheet
    // runs, so one place decides what may be sold and one set of sentences
    // says why not.
    final ItemTransitionCheck check = ItemTransition.check(
      item,
      ItemStatus.sold,
    );
    final bool canSell = check.isAllowed;

    return AppListRow(
      title: item.title,
      // The reason takes the caption's place on a row that cannot be sold:
      // what platform it is on matters less than why it is not for sale.
      subtitle: canSell
          ? _subtitle(context)
          : ItemBlockPresenter.messages(context, check.blocks),
      // A ticked row reads as ticked without reading the words — and the row
      // still carries its own title, so colour is never the only signal.
      icon: switch ((canSell, isSelected)) {
        (false, _) => AppIconConstant.warning,
        (true, true) => AppIconConstant.checkCircle,
        (true, false) => AppIconConstant.inventory,
      },
      iconTint: canSell
          ? (isSelected ? context.colorScheme3.primary : null)
          : context.sdTheme3.warning,
      // What the seller expects for it — `—` when nobody entered one, never a
      // zero (hard rule 5).
      trailingText: context.money(item.expectedPrice),
      showChevron: !isSelecting,
      isEnabled: canSell,
      // Long-press starts the bundle, the same gesture Inventory's selection
      // uses. A tick box in every row would be permanent chrome for something
      // most sales are not.
      onLongPress: () =>
          ref.read(recordSaleSelectionProvider.notifier).toggle(item.id),
      onTap: isSelecting
          ? () => ref.read(recordSaleSelectionProvider.notifier).toggle(item.id)
          : () => _pick(context),
    );
  }
}

/// Nothing to sell, told apart from nothing matching the search.
///
/// The first is a business with an empty shelf and the way on is Inventory;
/// the second is a query, and the fix is already on screen.
class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({required this.hasAny});

  final bool hasAny;

  @override
  Widget build(BuildContext context) => AppListEmptyState(
    hasAny: hasAny,
    noMatchMessage: context.l10n.recordSaleNoMatch,
    emptyIcon: AppIconConstant.inventory,
    emptyTitle: context.l10n.recordSaleNothingToSellTitle,
    emptyMessage: context.l10n.recordSaleNothingToSellBody,
    emptyAction: SdButtonV3(
      variant: SdButtonVariantV3.primary,
      label: context.l10n.commonGoToInventory,
      onPressed: () => context.go(AppRoutes.inventory),
    ),
  );
}
