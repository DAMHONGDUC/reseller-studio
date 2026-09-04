part of 'record_sale_screen.dart';

/// The rows to pick from.
///
/// **The inventory card, not a list row** — owner's rule. A seller picking a
/// jacket recognises it by its photo, its tags and what it cost, which is why
/// Inventory's list is cards; a chooser that strips all of that asks them to
/// identify stock by its title alone. The card lives in `core/widgets/` so
/// both features can draw it without either reaching into the other's
/// `presentation/`.
class _SaleItemList extends ConsumerWidget {
  const _SaleItemList({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Grouped once for the whole list, never watched per row: a family watch
    // on every row is one subscription each and a rebuild storm on any
    // listing write.
    final Map<String, List<Listing>> listings = ListingsByItem.group(
      ref.watch(listingsProvider).value ?? const <Listing>[],
    );
    final Set<String> selected = ref.watch(recordSaleSelectionProvider);
    // One instant for the whole build, so every row agrees about what stale
    // means — the same reason Inventory's list passes it down.
    final DateTime now = ref.watch(clockProvider).now();

    return ListView.separated(
      padding: SdContentPaddingV3.screen(context),
      itemCount: items.length,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: SdContentPaddingV3.listItemGap),
      itemBuilder: (BuildContext context, int index) => _SaleItemRow(
        item: items[index],
        listings: listings[items[index].id] ?? const <Listing>[],
        now: now,
        isSelected: selected.contains(items[index].id),
        isSelecting: selected.isNotEmpty,
      ),
    );
  }
}

/// One item to sell.
///
/// **A row that cannot be sold still takes the tap** — owner's rule. It
/// carries the reason on its warning line and opens `CannotSellSheet` when
/// tapped: a greyed card says the seller did something wrong and offers
/// nothing, which is worse than the filtered-out row it replaced.
class _SaleItemRow extends ConsumerWidget {
  const _SaleItemRow({
    required this.item,
    required this.listings,
    required this.now,
    required this.isSelected,
    required this.isSelecting,
  });

  final Item item;

  /// This item's live listings, for the card's marketplace count.
  final List<Listing> listings;

  final DateTime now;

  /// Whether this row is part of the bundle being built.
  final bool isSelected;

  /// Whether a bundle is being built at all. Once it is, a tap adds and
  /// removes rather than opening the sheet — otherwise the seller's second
  /// tap would sell one item instead of joining it to the others.
  final bool isSelecting;

  /// Picking an item opens the sheet; a recorded sale closes this screen so
  /// the seller lands back on Orders with the new order under them.
  Future<void> _pick(BuildContext context) async {
    final bool? recorded = await MarkSoldSheet.show(context, <Item>[item]);

    if (!context.mounted || !(recorded ?? false)) return;

    context.pop();
  }

  /// A tap or a long-press on a row that cannot be sold — both explain rather
  /// than doing nothing, since a long-press would otherwise start a bundle
  /// this item cannot join.
  Future<void> _explain(BuildContext context, ItemTransitionCheck check) =>
      CannotSellSheet.show(context, item: item, blocks: check.blocks);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The same check the actions sheet runs, so one place decides what may be
    // sold and one set of sentences says why not.
    final ItemTransitionCheck check = ItemTransition.check(
      item,
      ItemStatus.sold,
    );

    return ItemCard(
      item: item,
      listings: listings,
      now: now,
      isSelected: isSelected,
      isSelecting: isSelecting,
      notice: check.isAllowed
          ? null
          : ItemBlockPresenter.messages(context, check.blocks),
      // Neither the actions button nor the marketplace arrow is wired: this
      // screen's tap is the sale, and a second verb on the row would take the
      // seller out of the flow they came for.
      onTap: switch ((check.isAllowed, isSelecting)) {
        (false, _) => () => _explain(context, check),
        (true, true) =>
          () => ref.read(recordSaleSelectionProvider.notifier).toggle(item.id),
        (true, false) => () => _pick(context),
      },
      // Long-press starts the bundle, the same gesture Inventory's selection
      // uses. A tick box in every row would be permanent chrome for something
      // most sales are not.
      onLongPress: check.isAllowed
          ? () => ref.read(recordSaleSelectionProvider.notifier).toggle(item.id)
          : () => _explain(context, check),
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
