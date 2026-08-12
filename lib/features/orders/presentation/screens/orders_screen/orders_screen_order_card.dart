part of 'orders_screen.dart';

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.now,
    required this.onTap,
  });

  final Order order;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = order.isOverdue(now) ?? false;
    final Money? profit = order.profit().netProfit;

    return SdCardV3(
      onTap: onTap,
      // A tinted edge, and a "Late" badge saying the same thing — colour is
      // never the only signal.
      borderColor: isOverdue ? context.sdTheme3.danger : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  order.lines.isEmpty
                      ? 'Order ${order.id}'
                      : order.lines.first.title,
                  style: context.textTheme3.bodyLarge!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Text(
                context.money(order.salePrice),
                style: context.textTheme3.bodyLarge!.semiBold3.tabular3
                    .copyWith(color: context.sdTheme3.textPrimary),
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Wrap(
            spacing: SdSpacingConstant.w6,
            runSpacing: SdSpacingConstant.h4,
            children: <Widget>[
              SdBadgeV3(
                label: _statusLabel(order.status),
                tone: _statusTone(order.status),
              ),
              SdBadgeV3(label: order.marketplace.displayName),
              if (isOverdue)
                const SdBadgeV3(
                  label: 'Late',
                  tone: SdBadgeToneV3.danger,
                  icon: Symbols.priority_high_rounded,
                ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Row(
            children: <Widget>[
              Text(
                order.buyerName ?? '—',
                style: context.textTheme3.bodySmall!.muted3(context),
              ),
              const Spacer(),
              Text(
                'Profit ',
                style: context.textTheme3.bodySmall!.faint3(context),
              ),
              Text(
                context.money(profit),
                style: context.textTheme3.bodySmall!.semiBold3.tabular3
                    .copyWith(
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

  static String _statusLabel(OrderStatus status) => switch (status) {
    OrderStatus.awaitingPayment => 'Awaiting payment',
    OrderStatus.toShip => 'To ship',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.returnRequested => 'Return requested',
    OrderStatus.returned => 'Returned',
    OrderStatus.refunded => 'Refunded',
    OrderStatus.cancelled => 'Cancelled',
  };

  static SdBadgeToneV3 _statusTone(OrderStatus status) => switch (status) {
    OrderStatus.awaitingPayment => SdBadgeToneV3.warning,
    OrderStatus.toShip => SdBadgeToneV3.warning,
    OrderStatus.shipped => SdBadgeToneV3.info,
    OrderStatus.delivered => SdBadgeToneV3.success,
    OrderStatus.returnRequested => SdBadgeToneV3.danger,
    OrderStatus.returned => SdBadgeToneV3.neutral,
    OrderStatus.refunded => SdBadgeToneV3.neutral,
    OrderStatus.cancelled => SdBadgeToneV3.neutral,
  };
}
