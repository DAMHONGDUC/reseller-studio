part of 'order_detail_screen.dart';

/// The supplier half of a dropship sale: whether it has been ordered, what
/// it cost, and where the parcel is (`docs/DROPSHIPPING_PLAN.md`).
///
/// **It owns its header and is absent on a sale with no dropship line.**
class _SupplierSection extends ConsumerWidget {
  const _SupplierSection({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, Item> items = <String, Item>{
      for (final Item item in ref.watch(itemsProvider).value ?? const <Item>[])
        item.id: item,
    };
    final List<OrderLine> dropship = <OrderLine>[
      for (final OrderLine line in order.lines)
        if (items[line.itemId]?.isDropship ?? false) line,
    ];
    final List<SupplierOrder> placed = ref.watch(
      supplierOrdersForOrderProvider(order.id),
    );

    if (dropship.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: SdContentPaddingV3.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _OrderSectionTitle(title: context.l10n.itemSupplierSection),
          SizedBox(height: SdSpacingConstant.h8),
          for (final OrderLine line in dropship) ...<Widget>[
            _SupplierLineCard(
              order: order,
              line: line,
              supplierOrder: placed
                  .where(
                    (SupplierOrder so) =>
                        so.itemId == line.itemId &&
                        so.status != SupplierOrderStatus.cancelled,
                  )
                  .firstOrNull,
            ),
            SizedBox(height: SdSpacingConstant.h8),
          ],
        ],
      ),
    );
  }
}

/// One dropship line: the way to order it, or the order it already has.
class _SupplierLineCard extends ConsumerWidget {
  const _SupplierLineCard({
    required this.order,
    required this.line,
    required this.supplierOrder,
  });

  final Order order;
  final OrderLine line;
  final SupplierOrder? supplierOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SupplierProduct? product = SupplierCost.primaryFor(
      line.itemId,
      ref.watch(activeSupplierProductsProvider),
    );
    final SupplierOrder? current = supplierOrder;

    return SdCardV3(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            line.title,
            style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h6),
          if (current == null)
            _NotOrdered(order: order, line: line, product: product)
          else
            _Ordered(
              order: order,
              supplierOrder: current,
              shippingDays: product?.shippingDays,
            ),
        ],
      ),
    );
  }
}

class _NotOrdered extends StatelessWidget {
  const _NotOrdered({
    required this.order,
    required this.line,
    required this.product,
  });

  final Order order;
  final OrderLine line;
  final SupplierProduct? product;

  @override
  Widget build(BuildContext context) {
    final SupplierProduct? supplier = product;
    final String? url = supplier?.url;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          supplier == null
              ? context.l10n.itemSupplierNone
              : context.l10n.supplierOrderNotYet,
          style: context.textTheme3.bodySmall!.copyWith(
            color: context.sdTheme3.warning,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h12),
        if (url != null) ...<Widget>[
          SdButtonV3(
            variant: SdButtonVariantV3.secondary,
            label: context.l10n.supplierOrderOpenSupplier,
            icon: AppIconConstant.openInNew,
            size: SdButtonSizeV3.small,
            expand: true,
            onPressed: () => LinkUtils.open(url),
          ),
          SizedBox(height: SdSpacingConstant.h8),
        ],
        SdButtonV3(
          variant: SdButtonVariantV3.primary,
          label: context.l10n.supplierOrderPlaceTitle,
          size: SdButtonSizeV3.small,
          expand: true,
          onPressed: supplier == null
              ? null
              : () => PlaceSupplierOrderSheet.show(
                  context,
                  order: order,
                  line: line,
                  product: supplier,
                ),
        ),
      ],
    );
  }
}

class _Ordered extends ConsumerWidget {
  const _Ordered({
    required this.order,
    required this.supplierOrder,
    required this.shippingDays,
  });

  final Order order;
  final SupplierOrder supplierOrder;
  final int? shippingDays;

  Future<void> _refund(BuildContext context, WidgetRef ref) =>
      PriceEntrySheet.show(
        context,
        title: context.l10n.supplierOrderRefundTitle,
        fieldLabel: context.l10n.supplierOrderRefundLabel,
        submitLabel: context.l10n.actionSave,
        initialPrice: supplierOrder.supplierRefund,
        onSubmit: (Money amount) => ref
            .read(supplierOrderControllerProvider.notifier)
            .recordRefund(supplierOrder, order, amount),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SupplierOrderController controller = ref.read(
      supplierOrderControllerProvider.notifier,
    );
    final DateTime now = ref.watch(clockProvider).now();
    final int? waiting = SupplierOrders.daysAwaitingShipment(
      supplierOrder,
      now,
    );
    final DateTime? arrival = SupplierOrders.estimatedArrival(
      supplierOrder,
      shippingDays,
    );
    final bool late = SupplierOrders.isLate(
      supplierOrder,
      now,
      SupplierOrderConstant.lateAfterDays,
    );
    final TextStyle muted = context.textTheme3.bodySmall!.muted3(context);
    final List<String> facts = <String>[
      if (supplierOrder.externalSupplierOrderId != null)
        '#${supplierOrder.externalSupplierOrderId}',
      context.money(SupplierOrders.netCost(supplierOrder)),
      if (supplierOrder.trackingNumber != null) supplierOrder.trackingNumber!,
      if (arrival != null)
        context.l10n.supplierOrderArrival(
          DateTimeUtils.mediumDate(arrival, locale: context.localeTag),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: SdSpacingConstant.w8,
          runSpacing: SdSpacingConstant.h4,
          children: <Widget>[
            SdBadgeV3(
              label: supplierOrder.status.label(context),
              color: supplierOrder.status.color(context),
            ),
            if (waiting != null)
              SdBadgeV3(
                label: context.l10n.supplierOrderWaitingDays(waiting),
                tone: late ? SdBadgeToneV3.danger : SdBadgeToneV3.neutral,
              ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h6),
        Text(facts.join(' · '), style: muted.tabular3),
        SizedBox(height: SdSpacingConstant.h12),
        Wrap(
          spacing: SdSpacingConstant.w8,
          runSpacing: SdSpacingConstant.h8,
          children: <Widget>[
            if (supplierOrder.status == SupplierOrderStatus.placed)
              SdButtonV3(
                variant: SdButtonVariantV3.primary,
                label: context.l10n.supplierOrderTrackingTitle,
                size: SdButtonSizeV3.small,
                onPressed: () => SupplierTrackingSheet.show(
                  context,
                  supplierOrder: supplierOrder,
                  order: order,
                ),
              ),
            if (supplierOrder.status == SupplierOrderStatus.shipped)
              SdButtonV3(
                variant: SdButtonVariantV3.secondary,
                label: context.l10n.supplierOrderMarkDelivered,
                size: SdButtonSizeV3.small,
                onPressed: () => controller.markDelivered(supplierOrder),
              ),
            SdButtonV3(
              variant: SdButtonVariantV3.outlined,
              label: context.l10n.supplierOrderRefundTitle,
              size: SdButtonSizeV3.small,
              onPressed: () => _refund(context, ref),
            ),
            if (supplierOrder.status == SupplierOrderStatus.placed)
              SdButtonV3(
                variant: SdButtonVariantV3.text,
                label: context.l10n.supplierOrderCancel,
                size: SdButtonSizeV3.small,
                onPressed: () => controller.cancel(supplierOrder, order),
              ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h12),
        SdFieldLabelV3(label: context.l10n.supplierOrderInvoice),
        SizedBox(height: SdSpacingConstant.h6),
        ReceiptField(
          url: supplierOrder.invoiceUrl,
          isBusy: ref.watch(supplierOrderControllerProvider),
          onCamera: () =>
              controller.attachInvoice(supplierOrder, fromCamera: true),
          onLibrary: () =>
              controller.attachInvoice(supplierOrder, fromCamera: false),
          onRemove: () => controller.removeInvoice(supplierOrder),
        ),
      ],
    );
  }
}
