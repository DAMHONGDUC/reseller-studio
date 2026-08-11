import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/enums/order_status.dart';
import '../../../providers.dart';

/// Orders — "what am I selling and processing?".
///
/// Tabs are `All | To Ship | Shipped | Delivered | Returns` (plan §8), and
/// Offers live under this tab rather than as a sixth bottom tab.
///
/// **To Ship is the tab that matters**; everything else is history. An
/// overdue order is called out in red on its row, because the shipping
/// deadline is the one thing here with an external penalty attached.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> orders = ref.watch(visibleOrdersProvider);
    final AsyncValue<List<Order>> source = ref.watch(ordersProvider);

    return SdScaffoldV3(
      appBar: const SdAppBarV3(title: 'Orders'),
      body: Column(
        children: <Widget>[
          const _OrderFilterStrip(),
          Expanded(
            child: switch (source) {
              AsyncLoading<List<Order>>() when !source.hasValue =>
                const SdLoadingV3Page(),
              AsyncError<List<Order>>() => const SdEmptyStateV3(
                icon: Symbols.error_rounded,
                title: 'Could not load orders',
                message: 'Please try again.',
              ),
              _ when orders.isEmpty => const SdEmptyStateV3(
                icon: Symbols.receipt_long_rounded,
                title: 'Nothing here',
                message: 'No orders match this filter.',
              ),
              _ => _OrderList(orders: orders),
            },
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return ListView.separated(
      padding: SdContentPaddingV3.screen(context),
      itemCount: orders.length,
      separatorBuilder: (BuildContext context, int index) =>
          SizedBox(height: SdContentPaddingV3.listItemGap),
      itemBuilder: (BuildContext context, int index) =>
          _OrderCard(order: orders[index], now: now),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.now});

  final Order order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = order.isOverdue(now) ?? false;
    final Money? profit = order.profit().netProfit;

    return SdCardV3(
      onTap: () {},
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

class _OrderFilterStrip extends ConsumerWidget {
  const _OrderFilterStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OrderFilter selected = ref.watch(orderFilterProvider);
    final Map<OrderFilter, int> counts = ref.watch(orderCountsProvider);

    return SizedBox(
      height: SdSpacingConstant.h56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV3.horizontal,
          vertical: SdSpacingConstant.h8,
        ),
        itemCount: OrderFilter.values.length,
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(width: SdSpacingConstant.w8),
        itemBuilder: (BuildContext context, int index) {
          final OrderFilter filter = OrderFilter.values[index];

          return SdFilterChipV3(
            label: filter.label,
            count: counts[filter],
            selected: filter == selected,
            onSelected: () =>
                ref.read(orderFilterProvider.notifier).select(filter),
          );
        },
      ),
    );
  }
}
