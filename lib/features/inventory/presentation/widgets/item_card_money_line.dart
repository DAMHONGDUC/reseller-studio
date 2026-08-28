part of 'item_card.dart';

/// What it cost, what it is being asked for, and what the difference is.
///
/// **Three lines, stacked** — owner's rule. Figures sharing a line each got
/// half the width and truncated in turn; each on its own line has the whole
/// card to spell itself out, and the three read down as a small statement:
/// what went out, what is being asked, what is left.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MoneyCell(
          label: context.l10n.itemCost,
          value: context.money(item.purchasePrice),
          color: context.sdTheme3.textSecondary,
        ),
        SizedBox(height: SdSpacingConstant.h4),
        _MoneyCell(
          label: context.l10n.itemAsking,
          value: context.money(item.askingPrice),
          color: context.sdTheme3.textPrimary,
        ),
        SizedBox(height: SdSpacingConstant.h4),
        _MoneyCell(
          label: context.l10n.itemProfit,
          value: context.money(profit),
          // Hard rule 5: an em dash is not a figure, so it must not be tinted
          // as though it were good news or bad.
          color: profit == null
              ? context.sdTheme3.textTertiary
              : profit.isNegative
              ? context.sdTheme3.loss
              : context.sdTheme3.profit,
        ),
      ],
    );
  }
}
