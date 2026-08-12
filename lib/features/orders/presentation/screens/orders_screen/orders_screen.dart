import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/enums/order_status.dart';
import '../../../providers.dart';

part 'orders_screen_order_card.dart';
part 'orders_screen_order_filter_strip.dart';
part 'orders_screen_order_list.dart';

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
      appBar: SdAppBarV3(
        title: 'Orders',
        actions: <Widget>[
          IconButton(
            icon: const SdIconV3(Symbols.local_offer_rounded),
            tooltip: 'Offers',
            onPressed: () => context.push(AppRoutes.offers),
          ),
          IconButton(
            icon: const SdIconV3(Symbols.local_shipping_rounded),
            tooltip: 'Shipping queue',
            onPressed: () => context.push(AppRoutes.shippingQueue),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
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
