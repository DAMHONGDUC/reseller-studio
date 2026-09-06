import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/widgets/app_active_filter_bar.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_filter_strip.dart';
import '../../../../../core/widgets/app_list_empty_state.dart';
import '../../../../../core/widgets/app_marketplace_tag.dart';
import '../../../../../core/widgets/app_row_chevron.dart';
import '../../../../../core/widgets/plan_limit_meters.dart';
import '../../../../subscription/domain/enums/plan_allowance.dart';
import '../../../../subscription/domain/services/plan_gate.dart';
import '../../../../subscription/presentation/widgets/plan_block_sheet.dart';
import '../../../../subscription/providers.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/enums/order_status.dart';
import '../../../providers.dart';
import '../../order_filter_label.dart';
import '../../order_status_label.dart';
import '../../widgets/order_filter_sheet.dart';

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
///
/// **The create button records a sale** — the second of the two ways an order
/// exists (`lib/features/orders/CLAUDE.md`). Until it was here, the one screen
/// about selling was the one screen a seller could not record a sale on.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  Future<void> _recordSale(BuildContext context, WidgetRef ref) async {
    final PlanBlock block = ref.read(addOrderBlockProvider);

    if (block == PlanBlock.none) {
      await context.push(AppRoutes.recordSale);

      return;
    }

    if (!context.mounted) return;

    await PlanBlockSheet.show(
      context,
      block: block,
      plan: ref.read(currentPlanProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> orders = ref.watch(visibleOrdersProvider);
    final AsyncValue<List<Order>> source = ref.watch(ordersProvider);

    return AppAddFabScaffold(
      // Orders is a tab screen, so the button clears the glass bar.
      floatingNav: true,
      addLabel: context.l10n.recordSaleTitle,
      onAdd: () => _recordSale(context, ref),
      appBar: SdAppBarV3(
        title: context.l10n.navOrders,
        actions: <Widget>[
          // The screen's own control leads, ahead of the two that navigate
          // somewhere else.
          SdAppBarActionButtonV3(
            icon: AppIconConstant.filterAlt,
            tooltip: context.l10n.filterTitle,
            // Lit while the sheet behind it is holding something — see
            // Inventory's, and the tab is not counted there either.
            isActive: ref.watch(orderCriteriaProvider).isActive,
            onPressed: () => OrderFilterSheet.show(context),
          ),
          SdAppBarActionButtonV3(
            icon: AppIconConstant.localOffer,
            tooltip: context.l10n.offersTitle,
            onPressed: () => context.push(AppRoutes.offers),
          ),
          SdAppBarActionButtonV3(
            icon: AppIconConstant.localShipping,
            tooltip: context.l10n.shippingQueueTitle,
            onPressed: () => context.push(AppRoutes.shippingQueue),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          const _OrderFilterStrip(),
          const _ActiveFilters(),
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
                // The same action the button is, in the same words. An empty
                // state that pointed somewhere else would teach a route the
                // seller then has to unlearn.
                emptyAction: SdButtonV3(
                  variant: SdButtonVariantV3.primary,
                  label: context.l10n.recordSaleTitle,
                  onPressed: () => _recordSale(context, ref),
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
