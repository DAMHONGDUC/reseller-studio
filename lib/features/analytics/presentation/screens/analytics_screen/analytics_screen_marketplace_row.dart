part of 'analytics_screen.dart';

class _MarketplaceRow extends StatelessWidget {
  const _MarketplaceRow({
    required this.row,
    required this.maxRevenue,
    required this.color,
  });

  final MarketplacePerformance row;
  final int maxRevenue;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              row.marketplace.displayName,
              style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
            ),
          ),
          Text(
            context.money(row.revenue),
            style: context.textTheme3.bodyMedium!.tabular3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
        ],
      ),
      SizedBox(height: SdSpacingConstant.h6),
      ClipRRect(
        borderRadius: SdRadiusV3.fullAll,
        child: LinearProgressIndicator(
          value: maxRevenue == 0 ? 0 : row.revenue.minor / maxRevenue,
          minHeight: SdSpacingConstant.h8,
          backgroundColor: context.sdTheme3.surfaceSunken,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      SizedBox(height: SdSpacingConstant.h6),
      Text(
        context.l10n.analyticsMarketplaceRowDetail(
          context.l10n.analyticsOrderCount(row.orderCount),
          context.money(row.fees),
          context.percent(row.feeRate, decimals: 1),
          context.money(row.profit),
        ),
        style: context.textTheme3.bodySmall!.muted3(context),
      ),
    ],
  );
}
