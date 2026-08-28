part of 'item_card.dart';

/// The band across the foot of the card: how many are left, what they cost,
/// what they are being asked for, what that would leave.
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
  Widget build(BuildContext context) {
    final Money? profit = item.expectedProfit;

    return Row(
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
        Expanded(
          flex: 3,
          child: _MoneyCell(
            label: context.l10n.itemProfit,
            value: context.money(profit),
            // Hard rule 5: an em dash is not a figure, so it must not be
            // tinted as though it were good news or bad.
            color: profit == null
                ? context.sdTheme3.textTertiary
                : profit.isNegative
                ? context.sdTheme3.loss
                : context.sdTheme3.profit,
          ),
        ),
      ],
    );
  }
}
