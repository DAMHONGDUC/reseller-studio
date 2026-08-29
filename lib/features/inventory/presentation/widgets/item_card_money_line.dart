part of 'item_card.dart';

/// The band across the foot of the card: how many are left, what they cost,
/// and the way into what each marketplace is asking for them.
///
/// **Expected profit is not here** — owner's rule. It is a figure derived from
/// an asking price nobody has been offered yet, so on a list row it competes
/// with the two facts beside it while claiming less than either. The detail
/// screen still shows it.
///
/// **Cells across the card's full width** — owner's rule that the row be
/// harmonious, answered with a grid. Stacked as lines the figures made the
/// card tall and left the labels marooned at the far edge; side by side
/// inside the top row they were squeezed between a photo and a button. Across
/// the foot, the labels share one baseline and the figures share the next.
///
/// **Spaced apart, not divided into shares** — owner's rule. The cells
/// measure themselves and `spaceBetween` puts the gaps where the content
/// leaves them: the count holds the card's left edge and the arrow holds its
/// right. Fixed flex shares spent width on a two-character count and then
/// ellipsized a four-figure price.
///
/// **The arrow is the same glyph every other card ends with** — owner's
/// rule. It is `AppRowChevron`, so it cannot come out a size or a grey of its
/// own, and its cell aligns to the end so it holds the card's right edge in
/// the same column as the chevrons on Orders and Offers.
///
/// **The asking price is not here, the arrow is** — owner's rule. What the
/// item is asked for is a per-marketplace number, so one figure on the row is
/// a price that may be true nowhere; the arrow opens the screen that lists
/// every marketplace's own.
///
/// Every amount renders `—` when unknown, which is most of the point: an item
/// added through Quick Add has none of them, and the row must say so rather
/// than imply the item was free. The count never does: how many are left is
/// always known, and it is zero once the item has gone.
class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.item, this.onMarketPrices});

  final Item item;

  /// Opens the marketplace prices. Null on a list that only displays, and
  /// while a bulk selection is open.
  final VoidCallback? onMarketPrices;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      _MoneyCell(
        label: context.l10n.itemQuantityShort,
        content: Text(
          item.quantityOnHand.toString(),
          style: context.textTheme3.bodyMedium!.bold3.tabular3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
      ),
      _MoneyCell(
        label: context.l10n.itemCost,
        content: Text(
          context.money(item.purchasePrice),
          style: context.textTheme3.bodyMedium!.bold3.tabular3.copyWith(
            color: context.sdTheme3.textSecondary,
          ),
        ),
      ),
      if (onMarketPrices == null)
        const SizedBox.shrink()
      // An item that has left inventory cannot be listed, so the screen the
      // arrow opens would refuse it. The labelled cell stays rather than
      // closing, which keeps Qty and Cost in one column down the whole list.
      else if (!item.status.isListable)
        _MoneyCell(
          label: context.l10n.inventoryPrice,
          content: SizedBox.square(dimension: AppRowChevron.size),
        )
      else
        _MoneyCell(
          label: context.l10n.inventoryPrice,
          content: AppRowChevron(
            semanticLabel: context.l10n.inventoryMarketPrices,
          ),
          tooltip: context.l10n.inventoryMarketPrices,
          onTap: onMarketPrices!,
        ),
    ],
  );
}
