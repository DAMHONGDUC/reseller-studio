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
/// **The quantity leads and is narrower than the rest**, because a count is
/// two characters where an amount is nine — equal quarters would spend the
/// width where it is not needed and ellipsize a four-figure price.
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
    children: <Widget>[
      Expanded(
        flex: 2,
        child: _MoneyCell(
          label: context.l10n.itemQuantityShort,
          value: item.quantityOnHand.toString(),
          color: context.sdTheme3.textPrimary,
        ),
      ),
      Expanded(
        flex: 3,
        child: _MoneyCell(
          label: context.l10n.itemCost,
          value: context.money(item.purchasePrice),
          color: context.sdTheme3.textSecondary,
        ),
      ),
      Expanded(
        flex: 3,
        child: _MoneyCell(
          label: context.l10n.itemAsking,
          value: context.money(item.askingPrice),
          color: context.sdTheme3.textPrimary,
        ),
      ),
    ],
  );
}
