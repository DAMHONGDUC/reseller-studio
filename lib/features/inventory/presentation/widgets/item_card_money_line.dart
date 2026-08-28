part of 'item_card.dart';

/// What it cost, and what selling it at the asking price would leave.
///
/// **Cost at the start, profit at the end**, so the profit lands under the
/// asking price above it and the two figures a seller compares sit in one
/// column at the card's edge.
///
/// Both render `—` when unknown, which is most of the point: an item added
/// through Quick Add has neither, and the row must say so rather than imply
/// the item was free.
class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final Money? profit = item.expectedProfit;
    final double? margin = item.expectedMargin;

    return Row(
      // Spread rather than packed: the profit belongs under the asking price
      // at the card's edge, where the two numbers read as one column.
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        // Two thirds of the line to the profit, one to the cost: a Row
        // splits equal flex equally, which truncated the longer cell while
        // the shorter one sat on width it did not need.
        Flexible(
          child: _MoneyCell(
            label: context.l10n.itemCost,
            value: context.money(item.purchasePrice),
            color: context.sdTheme3.textSecondary,
          ),
        ),
        if (profit != null) ...<Widget>[
          SizedBox(width: SdSpacingConstant.w12),
          Flexible(
            flex: 2,
            child: _MoneyCell(
              label: context.l10n.itemProfit,
              // The margin rides inside the same cell: a percentage is what
              // makes $140 a good number or a thin one, and reading it three
              // cards later is not the same information.
              value: margin == null
                  ? context.money(profit)
                  : context.l10n.itemProfitWithMargin(
                      context.money(profit),
                      context.percent(margin),
                    ),
              color: profit.isNegative
                  ? context.sdTheme3.loss
                  : context.sdTheme3.profit,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ],
    );
  }
}
