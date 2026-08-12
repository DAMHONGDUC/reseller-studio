part of 'order_detail_screen.dart';

/// The plan's profit statement (§9), for one order.
///
/// ```text
/// Revenue
/// - COGS
/// - Platform fees
/// - Shipping
/// - Other expenses
/// ----------------
/// Net Profit
/// ```
///
/// **Every figure is derived at read time** (hard rule 3): correcting a fee
/// corrects this without a migration, and a report run next year over the same
/// data produces the same number.
///
/// When the item's cost was never entered the bottom line renders `—`, not
/// zero (hard rule 5). Treating the missing cost as zero would report the
/// whole sale price as profit — the single most misleading thing this app
/// could tell a seller.
class _ProfitStatement extends StatelessWidget {
  const _ProfitStatement({required this.profit});

  final ProfitBreakdown profit;

  @override
  Widget build(BuildContext context) {
    final Money? net = profit.netProfit;

    return SdCardV3(
      child: Column(
        children: <Widget>[
          _OrderDetailRow(
            label: 'Revenue',
            value: context.money(profit.revenue),
          ),
          _OrderDetailRow(
            label: 'Cost of goods',
            value: context.money(profit.cogs),
          ),
          _OrderDetailRow(
            label: 'Platform fees',
            value: context.money(profit.fees),
          ),
          _OrderDetailRow(
            label: 'Shipping',
            value: context.money(profit.shipping),
          ),
          _OrderDetailRow(
            label: 'Other expenses',
            value: context.money(profit.otherExpenses),
          ),
          Divider(
            height: SdSpacingConstant.h16,
            thickness: 1,
            color: context.sdTheme3.divider,
          ),
          _OrderDetailRow(
            label: 'Net profit',
            value: context.money(net),
            isEmphasis: true,
            // An em dash is not a figure, so it must not be tinted as though
            // it were good or bad news.
            valueColor: net == null
                ? null
                : net.isNegative
                ? context.sdTheme3.loss
                : context.sdTheme3.profit,
          ),
          _OrderDetailRow(
            label: 'Margin',
            value: context.percent(profit.margin),
          ),
          _OrderDetailRow(label: 'ROI', value: context.percent(profit.roi)),
          if (!profit.isComplete) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h8),
            Text(
              'No cost recorded for one of these items, so profit cannot be '
              'worked out. Add it on the item and this fills in.',
              style: context.textTheme3.bodySmall!.copyWith(
                color: context.sdTheme3.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
