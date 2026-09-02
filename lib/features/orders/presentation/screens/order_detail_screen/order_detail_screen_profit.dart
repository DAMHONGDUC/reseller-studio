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
/// The read half of an editable section, so it draws no card of its own.
class _ProfitStatement extends StatelessWidget {
  const _ProfitStatement({required this.profit, this.feesField, this.feeNote});

  final ProfitBreakdown profit;

  /// Says what the estimate was built from, when the fee is one. Built by the
  /// caller because it names the marketplace and its rate, and the statement
  /// is handed a breakdown rather than an order.
  final String? feeNote;

  /// Replaces the platform-fee row while the section is being edited. **The
  /// one stored figure here** — everything else is derived (hard rule 3), so
  /// the statement keeps its shape and only that row becomes a box.
  final Widget? feesField;

  @override
  Widget build(BuildContext context) {
    final Money? net = profit.netProfit;

    return Column(
      children: <Widget>[
        _OrderDetailRow(
          label: context.l10n.commonRevenue,
          value: context.money(profit.revenue),
        ),
        _OrderDetailRow(
          label: context.l10n.commonCostOfGoods,
          value: context.money(profit.cogs),
        ),
        if (feesField != null)
          feesField!
        else
          _OrderDetailRow(
            label: profit.feesAreEstimated
                ? context.l10n.orderPlatformFeesEstimated
                : context.l10n.orderPlatformFees,
            value: context.money(profit.fees),
          ),
        _OrderDetailRow(
          label: context.l10n.commonShipping,
          value: context.money(profit.shipping),
        ),
        _OrderDetailRow(
          label: context.l10n.orderOtherExpenses,
          value: context.money(profit.otherExpenses),
        ),
        SdDividerV3(gap: SdSpacingConstant.h8),
        _OrderDetailRow(
          label: context.l10n.commonNetProfit,
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
          label: context.l10n.commonMargin,
          value: context.percent(profit.margin),
        ),
        _OrderDetailRow(
          label: context.l10n.commonRoi,
          value: context.percent(profit.roi),
        ),
        if (profit.feesAreEstimated && feeNote != null) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            feeNote!,
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
        ],
        if (!profit.isComplete) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            context.l10n.orderProfitIncomplete,
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.warning,
            ),
          ),
        ],
      ],
    );
  }
}
