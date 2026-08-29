part of 'order_detail_screen.dart';

/// The one thing the status says to do next, pinned to the bottom edge.
///
/// **One move, never a menu** — owner's rule. An order in a queue has exactly
/// one obvious next step, and it is the reason the seller opened the screen:
/// `toShip` ships, `shipped` gets marked delivered, a requested return gets
/// taken back in. Everything else is in `OrderActionsSheet`.
///
/// **Nothing at all when the order is finished.** Delivered, refunded and
/// cancelled have no next step, and a pinned bar holding a bookkeeping verb
/// would make the rare thing look like the expected one.
class _NextMove extends ConsumerWidget {
  const _NextMove({required this.order});

  final Order order;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
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
    final bool isBusy = ref.watch(orderActionsControllerProvider);
    final OrderActionsController actions = ref.read(
      orderActionsControllerProvider.notifier,
    );

    final (String, VoidCallback)? move = switch (order.status) {
      OrderStatus.toShip => (
        context.l10n.orderShipIt,
        () => ShipOrderSheet.show(context, order),
      ),
      OrderStatus.shipped => (
        context.l10n.orderMarkDelivered,
        () => _run(context, () => actions.markDelivered(order)),
      ),
      OrderStatus.returnRequested => (
        context.l10n.orderItemCameBack,
        () => _confirmReturn(context, ref),
      ),
      OrderStatus.awaitingPayment ||
      OrderStatus.delivered ||
      OrderStatus.returned ||
      OrderStatus.refunded ||
      OrderStatus.cancelled => null,
    };

    if (move == null) return const SizedBox.shrink();

    return AppPinnedAction(
      label: move.$1,
      isBusy: isBusy,
      onPressed: isBusy ? null : move.$2,
    );
  }
}
