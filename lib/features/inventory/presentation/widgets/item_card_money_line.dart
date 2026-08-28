part of 'item_card.dart';

/// The band across the foot of the card: what went out, what is being asked,
/// what is left.
///
/// **Three equal cells across the card's full width** — owner's rule that the
/// row be harmonious, answered with a grid. Stacked as three lines the figures
/// made the card tall and left the labels marooned at the far edge; side by
/// side they were squeezed between a photo and a button. Across the foot,
/// each has a third of the card, the labels share a baseline and the amounts
/// share the next.
///
/// Every one renders `—` when unknown, which is most of the point: an item
/// added through Quick Add has none of them, and the row must say so rather
/// than imply the item was free.
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
          child: _MoneyCell(
            label: context.l10n.itemCost,
            value: context.money(item.purchasePrice),
            color: context.sdTheme3.textSecondary,
          ),
        ),
        Expanded(
          child: _MoneyCell(
            label: context.l10n.itemAsking,
            value: context.money(item.askingPrice),
            color: context.sdTheme3.textPrimary,
          ),
        ),
        Expanded(
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
