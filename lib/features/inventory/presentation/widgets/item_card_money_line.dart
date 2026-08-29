part of 'item_card.dart';

/// The band across the foot of the card: how many are left, what they cost,
/// and what they are being asked for.
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
/// leaves them: the count holds the card's left edge and the asking price
/// holds its right. Fixed flex shares spent width on a two-character count
/// and then ellipsized a four-figure price.
///
/// Every amount renders `—` when unknown, which is most of the point: an item
/// added through Quick Add has none of them, and the row must say so rather
/// than imply the item was free. The count never does: how many are left is
/// always known, and it is zero once the item has gone.
class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      _MoneyCell(
        label: context.l10n.itemQuantityShort,
        value: item.quantityOnHand.toString(),
        color: context.sdTheme3.textPrimary,
      ),
      _MoneyCell(
        label: context.l10n.itemCost,
        value: context.money(item.purchasePrice),
        color: context.sdTheme3.textSecondary,
      ),
      _MoneyCell(
        label: context.l10n.itemAsking,
        value: context.money(item.askingPrice),
        color: context.sdTheme3.textPrimary,
        // Flush with the card's edge: a space-between row ending on a
        // left-aligned amount reads as a column that did not reach.
        alignment: CrossAxisAlignment.end,
      ),
    ],
  );
}
