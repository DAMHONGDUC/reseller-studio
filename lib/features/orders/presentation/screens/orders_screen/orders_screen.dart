import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/widgets/app_filter_strip.dart';
import '../../../../../core/widgets/app_list_empty_state.dart';
import '../../../../../core/widgets/app_row_chevron.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/enums/order_status.dart';
import '../../../providers.dart';
import '../../order_filter_label.dart';
import '../../order_status_label.dart';

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
        title: context.l10n.navOrders,
        actions: <Widget>[
          IconButton(
            icon: const SdIconV3(AppIconConstant.localOffer),
            tooltip: context.l10n.offersTitle,
            onPressed: () => context.push(AppRoutes.offers),
          ),
          IconButton(
            icon: const SdIconV3(AppIconConstant.localShipping),
            tooltip: context.l10n.shippingQueueTitle,
            onPressed: () => context.push(AppRoutes.shippingQueue),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          const _OrderFilterStrip(),
          SizedBox(height: SdContentPaddingV3.topGap),
          Expanded(
            child: switch (source) {
              AsyncLoading<List<Order>>() when !source.hasValue =>
                const SdLoadingV3Page(),
              AsyncError<List<Order>>() => SdEmptyStateV3(
                icon: AppIconConstant.error,
                title: context.l10n.ordersLoadFailed,
                message: context.l10n.commonCouldNotLoad,
              ),
              _ when orders.isEmpty => AppListEmptyState(
                hasAny: (source.value ?? const <Order>[]).isNotEmpty,
                noMatchMessage: context.l10n.ordersNoMatch,
                emptyIcon: AppIconConstant.receiptLong,
                emptyTitle: context.l10n.ordersEmptyTitle,
                emptyMessage: context.l10n.ordersEmptyBody,
                // Orders have no create action of their own — one appears
                // when an item is marked sold — so the way on is upstream.
                emptyAction: SdButtonV3(
                  variant: SdButtonVariantV3.primary,
                  label: context.l10n.commonGoToInventory,
                  onPressed: () => context.go(AppRoutes.inventory),
                ),
              ),
              _ => _OrderList(orders: orders),
            },
          ),
        ],
      ),
    );
  }
}
