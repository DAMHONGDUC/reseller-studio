part of 'record_sale_screen.dart';

/// The rows to pick from.
///
/// **`AppListRow`, not the inventory card.** This is a chooser, the same job
/// the Search screen does with the same widget — the card belongs to the
/// screens that own the records, and reaching into Inventory's presentation
/// layer for it is what the dependency rule forbids.
class _SaleItemList extends StatelessWidget {
  const _SaleItemList({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context) => ListView(
    padding: SdContentPaddingV3.screen(context),
    children: <Widget>[
      AppListCard(
        children: items
            .map((Item item) => _SaleItemRow(item: item))
            .toList(growable: false),
      ),
    ],
  );
}

class _SaleItemRow extends StatelessWidget {
  const _SaleItemRow({required this.item});

  final Item item;

  /// Where it is, and what it is called on the shelf. The SKU earns its place
  /// because two items can carry the same title and only one of them sold.
  String _subtitle(BuildContext context) =>
      <String>[item.status.label(context), ?item.sku].join(' · ');

  /// Picking an item opens the sheet; a recorded sale closes this screen so
  /// the seller lands back on Orders with the new order under them.
  Future<void> _pick(BuildContext context) async {
    final bool? recorded = await MarkSoldSheet.show(context, item);

    if (!context.mounted || !(recorded ?? false)) return;

    context.pop();
  }

  @override
  Widget build(BuildContext context) => AppListRow(
    title: item.title,
    subtitle: _subtitle(context),
    icon: AppIconConstant.inventory,
    // The asking price, which is also what the sheet pre-fills — `—` when
    // nobody has entered one (hard rule 5).
    trailingText: context.money(item.askingPrice),
    onTap: () => _pick(context),
  );
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
