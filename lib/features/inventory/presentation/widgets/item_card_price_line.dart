part of 'item_card.dart';

/// Cost and asking price, side by side.
///
/// Both render `—` when unknown, which is most of the point: an item added
/// through Quick Add has neither, and the row must say so rather than imply
/// the item is free.
class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.item});

  final Item item;

  // Every cell is Flexible and every value ellipsizes. A fixed Row overflowed
  // by 35px once the amounts grew — money strings are as long as the numbers
  // in them, and a card cannot get wider.
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Flexible(
        child: _PriceCell(
          label: context.l10n.itemCost,
          value: context.money(item.purchasePrice),
          color: context.sdTheme3.textSecondary,
        ),
      ),
      SizedBox(width: SdSpacingConstant.w12),
      Flexible(
        child: _PriceCell(
          label: context.l10n.itemAsking,
          value: context.money(item.askingPrice),
          color: context.sdTheme3.textPrimary,
        ),
      ),
      if (item.expectedProfit != null) ...<Widget>[
        SizedBox(width: SdSpacingConstant.w12),
        Flexible(
          child: _PriceCell(
            label: context.l10n.itemProfit,
            value: context.money(item.expectedProfit),
            color: item.expectedProfit!.isNegative
                ? context.sdTheme3.loss
                : context.sdTheme3.profit,
          ),
        ),
      ],
    ],
  );
}
