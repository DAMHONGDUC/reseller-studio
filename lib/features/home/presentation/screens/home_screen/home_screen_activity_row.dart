part of 'home_screen.dart';

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final Money? profit = order.profit().netProfit;

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
              // A dash rather than an approximation: the payout is not in
              // yet, so this sale's profit is unknown (hard rule 5).
              Text(
                context.money(profit),
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
