part of 'order_detail_screen.dart';

/// The order, in blocks a seller can open one at a time.
///
/// **There is no edit screen** — the rule and its reasons are in
/// `docs/rules/SCREENS.md`. Three blocks carry their own Edit; the lines and
/// the timeline are records rather than fields, and the status moves only
/// through the verbs that carry its side effects
/// (`lib/features/orders/CLAUDE.md`).
class _OrderBody extends ConsumerStatefulWidget {
  const _OrderBody({required this.order});

  final Order order;

  @override
  ConsumerState<_OrderBody> createState() => _OrderBodyState();
}

class _OrderBodyState extends ConsumerState<_OrderBody> {
  final TextEditingController _buyer = TextEditingController();
  final TextEditingController _salePrice = TextEditingController();
  final TextEditingController _payout = TextEditingController();
  final TextEditingController _tracking = TextEditingController();
  final TextEditingController _shippingCost = TextEditingController();

  @override
  void dispose() {
    _buyer.dispose();
    _salePrice.dispose();
    _payout.dispose();
    _tracking.dispose();
    _shippingCost.dispose();
    super.dispose();
  }

  /// Fills this section's boxes from the record, then opens it. Seeding on
  /// every open is what makes Cancel a restore.
  void _startEdit(OrderDetailSection section) {
    final Order order = widget.order;

    switch (section) {
      case OrderDetailSection.order:
        _buyer.text = order.buyerName ?? '';
        _salePrice.text = order.salePrice.toInputString();
      case OrderDetailSection.profit:
        _payout.text = order.payout?.toInputString() ?? '';
      case OrderDetailSection.shipping:
        _tracking.text = order.trackingNumber ?? '';
        _shippingCost.text = order.shippingCost?.toInputString() ?? '';
    }

    ref.read(orderDetailEditControllerProvider.notifier).edit(section, order);
  }

  Future<void> _save(Future<void> Function() write) async {
    try {
      await write();
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Order order = widget.order;
    final List<Expense> attributed =
        ref.watch(expensesForOrderProvider(order.id)).value ??
        const <Expense>[];
    final OrderDetailEditState edit = ref.watch(
      orderDetailEditControllerProvider,
    );
    final OrderDetailEditController controller = ref.read(
      orderDetailEditControllerProvider.notifier,
    );
    final String currency = ref.watch(workspaceCurrencyProvider);

    // Costs already inside the order's own shipping figure are not added
    // again — counting a label twice understates profit.
    final Money? otherExpenses = attributed
        .map((Expense expense) => expense.amount)
        .totalOrNull();

    final ProfitBreakdown profit = order.profit(otherExpenses: otherExpenses);

    return ListView(
      padding: SdContentPaddingV3.screen(context),
      children: <Widget>[
        SizedBox(height: SdContentPaddingV3.topGap),
        _OrderSection(
          section: OrderDetailSection.order,
          title: context.l10n.orderSectionOrder,
          edit: edit,
          first: true,
          onEdit: _startEdit,
          onCancel: controller.cancel,
          onSave: () => _save(
            () => controller.saveOrder(
              orderId: order.id,
              buyerName: _buyer.text,
              salePrice: _salePrice.text,
            ),
          ),
          reading: _StatusCard(
            order: order,
            now: ref.watch(clockProvider).now(),
          ),
          editing: Column(
            children: <Widget>[
              MoneyField(
                label: context.l10n.commonRevenue,
                controller: _salePrice,
                currency: currency,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              SdTextFieldV3(
                label: context.l10n.markSoldBuyer,
                controller: _buyer,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              _OrderDateField(
                label: context.l10n.orderOrdered,
                selected: edit.orderedAt,
                onSelected: controller.selectOrderedAt,
              ),
            ],
          ),
        ),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _OrderSectionTitle(title: context.l10n.commonItems),
        SizedBox(height: SdSpacingConstant.h8),
        _OrderLines(order: order),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _OrderSection(
          section: OrderDetailSection.profit,
          title: context.l10n.commonProfit,
          edit: edit,
          onEdit: _startEdit,
          onCancel: controller.cancel,
          onSave: () => _save(
            () =>
                controller.saveProfit(orderId: order.id, payout: _payout.text),
          ),
          reading: _ProfitStatement(profit: profit),
          // The payout is the one stored figure on this statement; every other
          // line is derived from it (hard rule 3), so the statement keeps its
          // shape and gains a box rather than swapping a row for one.
          editing: _ProfitStatement(
            profit: profit,
            payoutField: MoneyField(
              label: context.l10n.settlePayout,
              controller: _payout,
              currency: currency,
              helperText: context.l10n.settlePayoutHelp,
              textInputAction: TextInputAction.done,
            ),
          ),
        ),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _OrderSection(
          section: OrderDetailSection.shipping,
          title: context.l10n.commonShipping,
          edit: edit,
          onEdit: _startEdit,
          onCancel: controller.cancel,
          onSave: () => _save(
            () => controller.saveShipping(
              orderId: order.id,
              trackingNumber: _tracking.text,
              shippingCost: _shippingCost.text,
            ),
          ),
          reading: _ShippingCard(order: order),
          editing: Column(
            children: <Widget>[
              _CarrierField(
                selected: edit.carrier,
                onSelected: controller.selectCarrier,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              SdTextFieldV3(
                label: context.l10n.orderTracking,
                controller: _tracking,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              _OrderDateField(
                label: context.l10n.orderShipBy,
                selected: edit.shipByDate,
                onSelected: controller.selectShipByDate,
                allowFuture: true,
              ),
              SizedBox(height: SdSpacingConstant.h16),
              MoneyField(
                label: context.l10n.orderShippingCost,
                controller: _shippingCost,
                currency: currency,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _OrderSectionTitle(title: context.l10n.orderTimeline),
        SizedBox(height: SdSpacingConstant.h8),
        _Timeline(order: order),
        SizedBox(height: SdContentPaddingV3.bottomGap),
      ],
    );
  }
}

/// One editable block: the header and its two bodies, wrapped in the card.
class _OrderSection extends StatelessWidget {
  const _OrderSection({
    required this.section,
    required this.title,
    required this.edit,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.reading,
    required this.editing,
    this.first = false,
  });

  final OrderDetailSection section;
  final String title;
  final OrderDetailEditState edit;
  final ValueChanged<OrderDetailSection> onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Widget reading;
  final Widget editing;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final bool isOpen = edit.isOpen(section);

    return AppEditableSection(
      title: title,
      first: first,
      isEditing: isOpen,
      isSaving: isOpen && edit.isSaving,
      // Null while another block is open: one draft at a time.
      onEdit: edit.editing == null ? () => onEdit(section) : null,
      onCancel: onCancel,
      onSave: onSave,
      child: SdCardV3(child: isOpen ? editing : reading),
    );
  }
}

/// A date on the order, picked rather than typed.
class _OrderDateField extends StatelessWidget {
  const _OrderDateField({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.allowFuture = false,
  });

  final String label;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  /// A ship-by deadline is in the future; the date an order was placed is
  /// not, and one filed there breaks every period report it lands in.
  final bool allowFuture;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return PickerField(
      label: label,
      icon: AppIconConstant.calendarMonth,
      value: selected == null
          ? null
          : DateTimeUtils.mediumDate(selected!, locale: context.localeTag),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selected ?? now,
          firstDate: DateTime(now.year - DatePickerConstant.taxRecordYearsBack),
          lastDate: allowFuture
              ? now.add(
                  const Duration(days: DatePickerConstant.deadlineDaysAhead),
                )
              : now,
        );

        if (picked == null) return;

        onSelected(picked);
      },
    );
  }
}

/// The couriers this business ships with, by name.
///
/// The name is stored rather than an id, which is what `ShipOrderSheet`
/// already writes — an order keeps the courier it went out with even after
/// the record is renamed or removed.
class _CarrierField extends ConsumerWidget {
  const _CarrierField({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Carrier> carriers = ref.watch(activeCarriersProvider);

    return PickerField(
      label: context.l10n.orderCarrier,
      icon: AppIconConstant.localShipping,
      value: selected,
      onTap: () async {
        final String? picked = await OptionPickerSheet.show<String>(
          context,
          title: context.l10n.orderCarrier,
          selected: selected,
          options: carriers
              .map(
                (Carrier carrier) => PickerOption<String>(
                  value: carrier.name,
                  label: carrier.name,
                ),
              )
              .toList(),
        );

        if (picked == null) return;

        onSelected(picked);
      },
    );
  }
}

/// Status, buyer and what the platform took — the three facts a seller checks
/// before deciding what to do.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order, required this.now});

  final Order order;
  final DateTime now;

  static SdBadgeToneV3 toneFor(OrderStatus status) => switch (status) {
    OrderStatus.toShip => SdBadgeToneV3.warning,
    OrderStatus.awaitingPayment => SdBadgeToneV3.neutral,
    OrderStatus.shipped => SdBadgeToneV3.info,
    OrderStatus.delivered => SdBadgeToneV3.success,
    OrderStatus.returnRequested => SdBadgeToneV3.danger,
    OrderStatus.returned || OrderStatus.refunded => SdBadgeToneV3.neutral,
    OrderStatus.cancelled => SdBadgeToneV3.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = order.isOverdue(now) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SdBadgeV3(
              label: OrderStatusLabel.of(context, order.status),
              tone: toneFor(order.status),
            ),
            if (isOverdue) ...<Widget>[
              SizedBox(width: SdSpacingConstant.w6),
              SdBadgeV3(
                label: context.l10n.orderOverdue,
                tone: SdBadgeToneV3.danger,
                icon: AppIconConstant.schedule,
              ),
            ],
          ],
        ),
        SizedBox(height: SdSpacingConstant.h12),
        Text(
          context.money(order.salePrice),
          style: context.textTheme3.headlineSmall!.bold3.tabular3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h4),
        Row(
          children: <Widget>[
            // The marketplace stays first in the line; the dot only colours
            // the name that is already there.
            AppMarketplaceDot(marketplaceId: order.marketplaceId),
            SizedBox(width: SdSpacingConstant.w6),
            Expanded(
              child: Text(
                <String>[
                  order.marketplaceName,
                  DateTimeUtils.mediumDate(
                    order.orderedAt,
                    locale: context.localeTag,
                  ),
                  if (order.buyerName != null) order.buyerName!,
                ].join(' · '),
                style: context.textTheme3.bodySmall!.faint3(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Carrier, tracking and the deadline.
class _ShippingCard extends StatelessWidget {
  const _ShippingCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final String dash = context.l10n.emptyValuePlaceholder;

    return Column(
      children: <Widget>[
        _OrderDetailRow(
          label: context.l10n.orderCarrier,
          value: order.carrier ?? dash,
        ),
        _TrackingRow(order: order),
        _OrderDetailRow(
          label: context.l10n.orderShipBy,
          value: order.shipByDate == null
              ? dash
              : DateTimeUtils.mediumDate(
                  order.shipByDate!,
                  locale: context.localeTag,
                ),
        ),
        _OrderDetailRow(
          label: context.l10n.orderShippingCost,
          value: context.money(order.shippingCost),
        ),
      ],
    );
  }
}

/// A label on the left, a figure on the right, tabular so a column of them
/// does not shuffle.
class _OrderDetailRow extends StatelessWidget {
  const _OrderDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final Color? valueColor;

  /// An action on the value — opening a tracking page, copying a number.
  final Widget? trailing;

  /// The bottom line of a statement. Heavier, and separated by a rule.
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = isEmphasis
        ? context.textTheme3.bodyLarge!.bold3.tabular3
        : context.textTheme3.bodyMedium!.semiBold3.tabular3;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: isEmphasis
                  ? context.textTheme3.bodyMedium!.semiBold3.copyWith(
                      color: context.sdTheme3.textPrimary,
                    )
                  : context.textTheme3.bodyMedium!.muted3(context),
            ),
          ),
          Text(
            value,
            style: valueStyle.copyWith(
              color: valueColor ?? context.sdTheme3.textPrimary,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _OrderSectionTitle extends StatelessWidget {
  const _OrderSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: context.textTheme3.titleSmall!.semiBold3.copyWith(
      color: context.sdTheme3.textPrimary,
    ),
  );
}

/// The tracking number, with the one thing a seller actually wants to do
/// with it.
///
/// **It was a string to read and retype.** Where the carrier's page is known
/// the number opens it; where it is not — an unrecognised courier, or `Other`
/// — it copies instead, which works everywhere. One action per row, chosen by
/// what is possible, rather than two buttons of which one is usually dead.
class _TrackingRow extends StatelessWidget {
  const _TrackingRow({required this.order});

  final Order order;

  Future<void> _open(BuildContext context, String url) async {
    final bool opened = await LinkUtils.open(url);

    // The failure is already logged inside LinkUtils; falling back to the
    // clipboard means the number is still usable when no browser answered.
    if (context.mounted && !opened) await _copy(context);
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: order.trackingNumber ?? ''));

    if (!context.mounted) return;

    SdSnackBarUtilsV3.success(context, context.l10n.orderTrackingCopied);
  }

  @override
  Widget build(BuildContext context) {
    final String? number = order.trackingNumber;

    if (number == null || number.trim().isEmpty) {
      return _OrderDetailRow(
        label: context.l10n.orderTracking,
        value: context.l10n.emptyValuePlaceholder,
      );
    }

    final String? url = OrdersTrackingConstant.url(
      carrier: order.carrier,
      number: number,
    );

    return _OrderDetailRow(
      label: context.l10n.orderTracking,
      value: number,
      trailing: AppRowIconButton(
        icon: url == null
            ? AppIconConstant.contentCopy
            : AppIconConstant.openInNew,
        tooltip: url == null
            ? context.l10n.orderCopyTracking
            : context.l10n.orderTrackParcel,
        tint: context.colorScheme3.primary,
        onPressed: () => url == null ? _copy(context) : _open(context, url),
      ),
    );
  }
}
