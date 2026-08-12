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

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  Future<void> _confirmReturn(BuildContext context, WidgetRef ref) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: 'The item came back',
        message:
            'Put it back on the shelf, or keep it out of inventory if it came '
            'back damaged.',
        icon: Symbols.assignment_return_rounded,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: 'Restock it',
            isPrimary: true,
            onPressed: () => _run(
              context,
              () => ref
                  .read(orderActionsControllerProvider.notifier)
                  .markReturned(order, restock: true),
              'Returned and restocked',
            ),
          ),
          SdDialogActionV3(
            label: 'Do not restock',
            onPressed: () => _run(
              context,
              () => ref
                  .read(orderActionsControllerProvider.notifier)
                  .markReturned(order, restock: false),
              'Returned',
            ),
          ),
          SdDialogActionV3(
            label: context.l10n.actionCancel,
            onPressed: () {},
          ),
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
            label: 'Ship it',
            icon: Symbols.local_shipping_rounded,
            expand: true,
            busy: isBusy,
            onPressed: () => ShipOrderSheet.show(context, order),
          ),
        if (order.status == OrderStatus.shipped) ...<Widget>[
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: 'Mark delivered',
            icon: Symbols.check_circle_rounded,
            expand: true,
            busy: isBusy,
            onPressed: () => _run(
              context,
              () => actions.markDelivered(order),
              'Marked delivered',
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
        ],
        if (order.status == OrderStatus.returnRequested) ...<Widget>[
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: 'It came back',
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
            label: 'Open a return',
            expand: true,
            busy: isBusy,
            onPressed: () => _run(
              context,
              () => actions.requestReturn(order),
              'Return opened',
            ),
          ),
        ],
        SizedBox(height: SdSpacingConstant.h8),
        SdButtonV3(
          variant: SdButtonVariantV3.secondary,
          label: 'Record fees and payout',
          expand: true,
          busy: isBusy,
          onPressed: () => SettleOrderSheet.show(context, order),
        ),
      ],
    );
  }
}
