part of 'order_detail_screen.dart';

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Expense> attributed =
        ref.watch(expensesForOrderProvider(order.id)).value ??
        const <Expense>[];

    // Costs already inside the order's own shipping figure are not added
    // again — counting a label twice understates profit.
    final Money? otherExpenses = attributed
        .map((Expense expense) => expense.amount)
        .totalOrNull();

    final ProfitBreakdown profit = order.profit(
      otherExpenses: otherExpenses,
    );

    return ListView(
      padding: SdContentPaddingV3.screen(context),
      children: <Widget>[
        SizedBox(height: SdContentPaddingV3.topGap),
        _StatusCard(order: order, now: ref.watch(clockProvider).now()),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _OrderSectionTitle(title: context.l10n.commonItems),
        _OrderLines(order: order),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _OrderSectionTitle(title: context.l10n.commonProfit),
        _ProfitStatement(profit: profit),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _OrderSectionTitle(title: context.l10n.commonShipping),
        _ShippingCard(order: order),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _OrderSectionTitle(title: context.l10n.orderTimeline),
        _Timeline(order: order),
        SizedBox(height: SdContentPaddingV3.sectionGap),
        _OrderActions(order: order),
        SizedBox(height: SdContentPaddingV3.bottomGap),
      ],
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

    return SdCardV3(
      child: Column(
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
                  icon: Symbols.schedule_rounded,
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
          Text(
            <String>[
              order.marketplace.displayName,
              DateTimeUtils.mediumDate(
                order.orderedAt,
                locale: context.localeTag,
              ),
              if (order.buyerName != null) order.buyerName!,
            ].join(' · '),
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
        ],
      ),
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

    return SdCardV3(
      child: Column(
        children: <Widget>[
          _OrderDetailRow(
            label: context.l10n.orderCarrier,
            value: order.carrier ?? dash,
          ),
          _OrderDetailRow(
            label: context.l10n.orderTracking,
            value: order.trackingNumber ?? dash,
          ),
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
      ),
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
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final Color? valueColor;

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
        ],
      ),
    );
  }
}

class _OrderSectionTitle extends StatelessWidget {
  const _OrderSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: SdSpacingConstant.h8),
    child: Text(
      title,
      style: context.textTheme3.titleSmall!.semiBold3.copyWith(
        color: context.sdTheme3.textPrimary,
      ),
    ),
  );
}
