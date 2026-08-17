part of 'analytics_screen.dart';

/// The plan's profit statement (§9), rendered as the subtraction it is.
///
/// Shown as a running deduction rather than four separate tiles because that
/// is how a seller checks it: revenue at the top, each cost taken off, net at
/// the bottom. Four tiles would show the same numbers and hide the arithmetic.
class _ProfitStatement extends StatelessWidget {
  const _ProfitStatement({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) => SdCardV3(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _StatementRow(
          label: context.l10n.commonRevenue,
          value: context.money(summary.revenue),
          isTotal: true,
        ),
        _StatementRow(
          label: context.l10n.commonCostOfGoods,
          value: context.money(summary.costOfGoodsSold),
          isDeduction: true,
        ),
        _StatementRow(
          label: context.l10n.commonExpenses,
          value: context.money(summary.totalExpenses),
          isDeduction: true,
        ),
        SdDividerV3(gap: SdSpacingConstant.h8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.l10n.commonNetProfit,
                style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
            ),
            Text(
              context.money(summary.netProfit),
              style: context.textTheme3.titleMedium!.bold3.tabular3.copyWith(
                color: summary.netProfit == null
                    ? context.sdTheme3.textTertiary
                    : summary.netProfit!.isNegative
                    ? context.sdTheme3.loss
                    : context.sdTheme3.profit,
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h8),
        // Wrap, not Row: three badges whose labels grow with the numbers in
        // them overflowed the card by 44px on a narrow screen. A Row cannot
        // give way; this drops to a second line instead.
        Wrap(
          spacing: SdSpacingConstant.w6,
          runSpacing: SdSpacingConstant.h4,
          children: <Widget>[
            SdBadgeV3(
              label: context.l10n.analyticsMarginValue(
                context.percent(summary.margin),
              ),
            ),
            SdBadgeV3(
              label: context.l10n.analyticsOrderCount(summary.orderCount),
            ),
            // Saying the figure is partial is the difference between a number
            // a seller can act on and one that quietly misleads.
            if (!summary.isProfitComplete)
              SdBadgeV3(
                label: context.l10n.commonPartial,
                tone: SdBadgeToneV3.warning,
                icon: Symbols.info_rounded,
              ),
          ],
        ),
      ],
    ),
  );
}
