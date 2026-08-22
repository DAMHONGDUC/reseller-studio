part of 'order_detail_screen.dart';

/// What the seller can do to this order right now.
///
/// **Only the moves that make sense from the current status are shown.** An
/// order that has already shipped has no "Ship" button, and the difference
/// between that and a greyed-out one is that this list is short enough to
/// read at a glance — which matters when the whole point of the Orders tab is
/// draining a queue.
class _OrderActions extends ConsumerWidget {
  const _OrderActions({required this.order});

  final Order order;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    try {
      await action();

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(context, done);
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
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.orderReturnDialogTitle,
        message: context.l10n.orderReturnDialogBody,
        icon: Symbols.assignment_return_rounded,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.orderRestock,
            isPrimary: true,
            onPressed: () => _run(
              context,
              () => ref
                  .read(orderActionsControllerProvider.notifier)
                  .markReturned(order, restock: true),
              context.l10n.orderRestocked,
            ),
          ),
          SdDialogActionV3(
            label: context.l10n.orderDoNotRestock,
            onPressed: () => _run(
              context,
              () => ref
                  .read(orderActionsControllerProvider.notifier)
                  .markReturned(order, restock: false),
              context.l10n.orderReturnedDone,
            ),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isBusy = ref.watch(orderActionsControllerProvider);
    final OrderActionsController actions = ref.read(
      orderActionsControllerProvider.notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (order.status == OrderStatus.toShip ||
            order.status == OrderStatus.awaitingPayment)
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.orderShipIt,
            icon: Symbols.local_shipping_rounded,
            expand: true,
            busy: isBusy,
            onPressed: () => ShipOrderSheet.show(context, order),
          ),
        if (order.status == OrderStatus.shipped) ...<Widget>[
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.orderMarkDelivered,
            icon: Symbols.check_circle_rounded,
            expand: true,
            busy: isBusy,
            onPressed: () => _run(
              context,
              () => actions.markDelivered(order),
              context.l10n.orderMarkedDelivered,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
        ],
        if (order.status == OrderStatus.returnRequested) ...<Widget>[
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.orderItemCameBack,
            icon: Symbols.assignment_return_rounded,
            expand: true,
            busy: isBusy,
            onPressed: () => _confirmReturn(context, ref),
          ),
          SizedBox(height: SdSpacingConstant.h8),
        ],
        if (order.status == OrderStatus.delivered ||
            order.status == OrderStatus.shipped) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h8),
          SdButtonV3(
            variant: SdButtonVariantV3.outlined,
            label: context.l10n.orderOpenReturn,
            expand: true,
            busy: isBusy,
            onPressed: () => _run(
              context,
              () => actions.requestReturn(order),
              context.l10n.orderReturnOpened,
            ),
          ),
        ],
        // Every status where money has actually changed hands. Not
        // `awaitingPayment` — there is nothing to give back — and not a
        // cancelled order, which never took the money in the first place.
        if (order.status.countsAsRevenue ||
            order.status == OrderStatus.returned ||
            order.status == OrderStatus.refunded) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h8),
          SdButtonV3(
            variant: SdButtonVariantV3.outlined,
            label: context.l10n.refundAction,
            icon: Symbols.currency_exchange_rounded,
            expand: true,
            busy: isBusy,
            onPressed: () => RefundSheet.show(context, order),
          ),
        ],
        SizedBox(height: SdSpacingConstant.h8),
        SdButtonV3(
          variant: SdButtonVariantV3.secondary,
          label: context.l10n.orderRecordSettlement,
          expand: true,
          busy: isBusy,
          onPressed: () => SettleOrderSheet.show(context, order),
        ),
      ],
    );
  }
}
