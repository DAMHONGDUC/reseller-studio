part of 'home_screen.dart';

class _ActivityRow extends ConsumerWidget {
  const _ActivityRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfitBreakdown breakdown = order.profit(
      feeRates: ref.watch(marketplaceFeeRatesProvider),
    );
    final Money? profit = breakdown.netProfit;

    return Padding(
      padding: SdContentPaddingV3.row,
      child: Row(
        children: <Widget>[
          SdIconTileV3(
            icon: AppIconConstant.shoppingBag,
            tint: context.sdTheme3.textSecondary,
            size: SdIconTileSizeV3.small,
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  order.lines.isEmpty
                      ? 'Order ${order.id}'
                      : order.lines.first.title,
                  style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: <Widget>[
                    AppMarketplaceDot(marketplaceId: order.marketplaceId),
                    SizedBox(width: SdSpacingConstant.w6),
                    Expanded(
                      child: Text(
                        order.marketplaceName,
                        style: context.textTheme3.bodySmall!.muted3(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                context.money(order.salePrice),
                style: context.textTheme3.bodyMedium!.semiBold3.tabular3
                    .copyWith(color: context.sdTheme3.textPrimary),
              ),
              Text(
                breakdown.feesAreEstimated && profit != null
                    ? context.l10n.commonApproximate(context.money(profit))
                    : context.money(profit),
                style: context.textTheme3.bodySmall!.tabular3.copyWith(
                  color: profit == null
                      ? context.sdTheme3.textTertiary
                      : profit.isNegative
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
}
