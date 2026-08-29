import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_sheet_action_row.dart';
import '../../../../core/widgets/app_sheet_option_list.dart';
import '../../domain/entities/order.dart';
import '../../domain/enums/order_status.dart';
import '../controllers/order_actions_controller.dart';
import 'refund_sheet.dart';
import 'settlement_sheet.dart';
import 'ship_order_sheet.dart';

/// Everything a seller can do to one order, in one sheet.
///
/// **The same shape Inventory has** — owner's rule. `ItemActionsSheet` is one
/// list of verbs reached from a small Actions button, and Orders wrote its own
/// grammar instead: a column of full-width buttons at the foot of the detail
/// screen, past four sections of content. A seller draining a To Ship queue
/// scrolled two screens to reach the one button they came for.
///
/// **Only the moves the status allows are listed.** A shipped order has no
/// Ship row, and the difference between that and a greyed-out one is that this
/// list stays short enough to read at a glance.
///
/// **The next move is here as well as pinned.** The pinned button is the fast
/// path; this is the complete list, so a verb added here cannot go missing
/// from the sheet a seller learned to open.
class OrderActionsSheet extends ConsumerWidget {
  const OrderActionsSheet({required this.order, super.key});

  final Order order;

  static Future<void> show(BuildContext context, Order order) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => OrderActionsSheet(order: order),
      );

  /// Runs an action, closes the sheet, and presents failures only.
  ///
  /// Success is silent: the screen behind already shows the new status, and a
  /// toast on top of it says the same thing twice.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      await action();

      if (!context.mounted) return;

      if (navigator.canPop()) navigator.pop();
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  Future<void> _confirmReturn(BuildContext context, WidgetRef ref) async {
    final OrderActionsController actions = ref.read(
      orderActionsControllerProvider.notifier,
    );

    Navigator.of(context).pop();

    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.orderReturnDialogTitle,
        message: context.l10n.orderReturnDialogBody,
        icon: AppIconConstant.assignmentReturn,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.orderRestock,
            isPrimary: true,
            onPressed: () =>
                _run(context, () => actions.markReturned(order, restock: true)),
          ),
          SdDialogActionV3(
            label: context.l10n.orderDoNotRestock,
            onPressed: () => _run(
              context,
              () => actions.markReturned(order, restock: false),
            ),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OrderActionsController actions = ref.read(
      orderActionsControllerProvider.notifier,
    );
    final bool canReturn =
        order.status == OrderStatus.delivered ||
        order.status == OrderStatus.shipped;

    final List<Widget> rows = <Widget>[
      if (order.status == OrderStatus.toShip)
        AppSheetActionRow(
          icon: AppIconConstant.localShipping,
          label: context.l10n.orderShipIt,
          onTap: () {
            Navigator.of(context).pop();
            ShipOrderSheet.show(context, order);
          },
        ),
      if (order.status == OrderStatus.shipped)
        AppSheetActionRow(
          icon: AppIconConstant.checkCircle,
          label: context.l10n.orderMarkDelivered,
          onTap: () => _run(context, () => actions.markDelivered(order)),
        ),
      if (order.status == OrderStatus.returnRequested)
        AppSheetActionRow(
          icon: AppIconConstant.assignmentReturn,
          label: context.l10n.orderItemCameBack,
          onTap: () => _confirmReturn(context, ref),
        ),
      if (canReturn)
        AppSheetActionRow(
          icon: AppIconConstant.assignmentReturn,
          label: context.l10n.orderOpenReturn,
          onTap: () => _run(context, () => actions.requestReturn(order)),
        ),
      // Every status where money has actually changed hands. Not
      // `awaitingPayment` — there is nothing to give back — and not a
      // cancelled order, which never took the money in the first place.
      if (order.status.countsAsRevenue || order.status == OrderStatus.returned)
        AppSheetActionRow(
          icon: AppIconConstant.currencyExchange,
          label: context.l10n.orderRefundBuyer,
          onTap: () {
            Navigator.of(context).pop();
            RefundSheet.show(context, order);
          },
        ),
      AppSheetActionRow(
        icon: AppIconConstant.payments,
        label: context.l10n.orderRecordSettlement,
        onTap: () {
          Navigator.of(context).pop();
          SettleOrderSheet.show(context, order);
        },
      ),
    ];

    return SdBottomSheetV3(
      title: context.l10n.orderTitle(order.marketplaceName),
      closeTooltip: context.l10n.commonClose,
      child: AppSheetOptionList(
        itemCount: rows.length,
        itemBuilder: (BuildContext context, int index) => rows[index],
      ),
    );
  }
}
