import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/utils/link_utils.dart';
import '../../../../../core/widgets/app_detail_action_button.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_pinned_action.dart';
import '../../../../../core/widgets/app_row_icon_button.dart';
import '../../../../expenses/domain/entities/expense.dart';
import '../../../../expenses/providers.dart';
import '../../../../pricing/domain/services/profit_calculator.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/enums/order_status.dart';
import '../../../orders_tracking_constant.dart';
import '../../../providers.dart';
import '../../controllers/order_actions_controller.dart';
import '../../order_status_label.dart';
import '../../widgets/order_actions_sheet.dart';
import '../../widgets/ship_order_sheet.dart';

part 'order_detail_screen_body.dart';
part 'order_detail_screen_next_move.dart';
part 'order_detail_screen_lines.dart';
part 'order_detail_screen_profit.dart';
part 'order_detail_screen_timeline.dart';

/// Order detail (plan §8).
///
/// The screen a seller opens to answer two questions: **what do I have to do
/// with this, and what did I actually make on it.**
///
/// **The next move is pinned and everything else is one tap away** — owner's
/// rule. The status implies exactly one move (ship it, mark it delivered, take
/// the return back in), so that button holds the bottom edge where a thumb is
/// and never scrolls; the rest live in `OrderActionsSheet`, opened from the
/// app bar, which is the same grammar Item Detail uses. They were a column of
/// four full-width buttons past four sections of content: a seller draining a
/// To Ship queue scrolled two screens to reach the one button they came for,
/// and the rare bookkeeping verb was as loud as the daily one.
///
/// Watches the order rather than taking it as an argument, so a teammate
/// shipping it shows here without a reload and a notification tap
/// (`selleros:///orders/ord-4`) works with only an id.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Order?> order = ref.watch(orderProvider(orderId));
    final Order? value = order.value;

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: value == null
            ? context.l10n.orderTitleFallback
            : context.l10n.orderTitle(value.marketplaceName),
        subtitle: value?.externalOrderId,
        actions: <Widget>[
          if (value != null)
            AppDetailActionButton(
              label: context.l10n.commonActions,
              onPressed: () => OrderActionsSheet.show(context, value),
            ),
        ],
      ),
      // Outside the body, so the button holds the bottom edge whatever the
      // list is scrolled to — and absent entirely when the order has no move
      // left, because a button that leads nowhere is worse than none.
      bottomNavigationBar: value == null ? null : _NextMove(order: value),
      body: switch (order) {
        AsyncLoading<Order?>() when !order.hasValue => const SdLoadingV3Page(),
        AsyncError<Order?>() => SdEmptyStateV3(
          icon: AppIconConstant.error,
          title: context.l10n.orderLoadFailed,
          message: context.l10n.commonCouldNotLoad,
        ),
        AsyncData<Order?>(value: null) => SdEmptyStateV3(
          icon: AppIconConstant.searchOff,
          title: context.l10n.orderNotFound,
          message: context.l10n.commonMayHaveBeenDeleted,
        ),
        _ => _OrderBody(order: value!),
      },
    );
  }
}
