part of 'analytics_screen.dart';

/// The plan's profit statement (§9), rendered as the subtraction it is.
///
/// Shown as a running deduction rather than four separate tiles because that
/// is how a seller checks it: revenue at the top, each cost taken off, net at
/// the bottom. Four tiles would show the same numbers and hide the arithmetic.
///
/// **It sits under `AppProfitHero`**, which carries the headline, the margin
/// and the partial flag — so this card is the working, not the answer.
class _ProfitStatement extends StatelessWidget {
  const _ProfitStatement({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) => AppSection(
    title: context.l10n.analyticsTheStatement,
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
      ],
    ),
  );
}
