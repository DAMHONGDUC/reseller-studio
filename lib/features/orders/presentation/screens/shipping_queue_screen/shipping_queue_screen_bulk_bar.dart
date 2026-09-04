part of 'shipping_queue_screen.dart';

/// The bar that appears once parcels are ticked.
///
/// **One post-office run, one carrier, one tap** (hard rule 16). Shipping
/// twelve parcels through the per-order sheet is twelve sheets, and eleven of
/// them ask the same question — so this asks the carrier once and ships the
/// run. Tracking numbers belong to single parcels and stay on the order.
class _ShipBulkBar extends ConsumerWidget {
  const _ShipBulkBar();

  /// Asks for the carrier, then ships everything ticked.
  ///
  /// A business with no carriers on file is never asked: the field is
  /// optional at the transition (plan §29), and a picker with nothing in it
  /// is a dead end between the seller and their queue.
  Future<void> _ship(BuildContext context, WidgetRef ref) async {
    final List<Order> orders = ref.read(selectedShippingOrdersProvider);
    final List<Carrier> carriers = ref.read(activeCarriersProvider);
    String? carrier;

    if (orders.isEmpty) return;

    if (carriers.isNotEmpty) {
      carrier = await OptionPickerSheet.show<String>(
        context,
        title: context.l10n.shippingBulkCarrierTitle(orders.length),
        options: carriers
            .map(
              (Carrier item) =>
                  PickerOption<String>(value: item.name, label: item.name),
            )
            .toList(),
      );

      // Dismissing the picker cancels the run rather than shipping it
      // unlabelled: the seller opened it to answer, not to skip.
      if (carrier == null || !context.mounted) return;
    }

    try {
      await ref
          .read(orderActionsControllerProvider.notifier)
          .markManyShipped(orders, carrier: carrier);

      if (!context.mounted) return;

      ref.read(shippingSelectionProvider.notifier).clear();
      SdSnackBarUtilsV3.success(
        context,
        context.l10n.shippingBulkDone(orders.length),
      );
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(shippingSelectionProvider).length;
    final bool isBusy = ref.watch(orderActionsControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: SdContentPaddingV3.horizontal,
        right: SdContentPaddingV3.horizontal,
        bottom: SdContentPaddingV3.bottom(context),
      ),
      child: SdCardV3(
        layer: SdCardLayerV3.elevated,
        elevated: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.l10n.shippingSelectedCount(count),
                    style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                  ),
                ),
                SdButtonV3(
                  variant: SdButtonVariantV3.text,
                  label: context.l10n.commonClear,
                  size: SdButtonSizeV3.small,
                  onPressed: () =>
                      ref.read(shippingSelectionProvider.notifier).clear(),
                ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h8),
            SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: context.l10n.shippingBulkShip,
              size: SdButtonSizeV3.small,
              expand: true,
              busy: isBusy,
              onPressed: isBusy ? null : () => _ship(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
