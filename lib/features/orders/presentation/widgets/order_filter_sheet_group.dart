part of 'order_filter_sheet.dart';

/// One group of the sheet, edited on the draft.
class _OrderFilterGroupView extends ConsumerWidget {
  const _OrderFilterGroupView({
    required this.group,
    required this.draft,
    required this.showTitle,
    required this.min,
    required this.max,
    required this.onEdit,
  });

  final OrderFilterGroup group;
  final OrderFilterCriteria draft;
  final bool showTitle;

  /// The sale range's two boxes, owned by the sheet so they outlive a
  /// rebuild of this group.
  final TextEditingController min;
  final TextEditingController max;

  final ValueChanged<OrderFilterCriteria> onEdit;

  List<AppFilterOption<PresenceFilter>> _presence(
    BuildContext context,
    String yes,
    String no,
  ) => <AppFilterOption<PresenceFilter>>[
    AppFilterOption<PresenceFilter>(
      value: PresenceFilter.any,
      label: context.l10n.filterAny,
    ),
    AppFilterOption<PresenceFilter>(value: PresenceFilter.present, label: yes),
    AppFilterOption<PresenceFilter>(value: PresenceFilter.absent, label: no),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? title = showTitle ? group.label(context) : null;

    return switch (group) {
      OrderFilterGroup.status => _StatusGroup(
        title: title,
        draft: draft,
        onEdit: onEdit,
      ),
      OrderFilterGroup.marketplace => AppFilterChipGroup<String>(
        title: title,
        options: <AppFilterOption<String>>[
          for (final MapEntry<String, String> entry
              in ref.watch(orderMarketplaceNamesProvider).entries)
            AppFilterOption<String>(value: entry.key, label: entry.value),
        ],
        selected: draft.marketplaceIds,
        onSelected: (String id) => onEdit(draft.withMarketplaceToggled(id)),
      ),
      OrderFilterGroup.ordered => AppFilterChipGroup<DateRangeFilter>(
        title: title,
        options: <AppFilterOption<DateRangeFilter>>[
          for (final DateRangeFilter range in DateRangeFilter.values)
            AppFilterOption<DateRangeFilter>(
              value: range,
              label: range.label(context),
            ),
        ],
        selected: <DateRangeFilter>{draft.ordered},
        onSelected: (DateRangeFilter value) => onEdit(draft.withOrdered(value)),
      ),
      OrderFilterGroup.deadline => AppFilterChipGroup<OrderDeadlineFilter>(
        title: title,
        options: <AppFilterOption<OrderDeadlineFilter>>[
          for (final OrderDeadlineFilter deadline in OrderDeadlineFilter.values)
            AppFilterOption<OrderDeadlineFilter>(
              value: deadline,
              label: deadline.label(context),
            ),
        ],
        selected: <OrderDeadlineFilter>{draft.deadline},
        onSelected: (OrderDeadlineFilter value) =>
            onEdit(draft.withDeadline(value)),
      ),
      OrderFilterGroup.payout => AppFilterChipGroup<PresenceFilter>(
        title: title,
        options: _presence(
          context,
          context.l10n.filterPayoutReceived,
          context.l10n.filterPayoutAwaiting,
        ),
        selected: <PresenceFilter>{draft.payout},
        onSelected: (PresenceFilter value) => onEdit(draft.withPayout(value)),
      ),
      OrderFilterGroup.tracking => AppFilterChipGroup<PresenceFilter>(
        title: title,
        options: _presence(
          context,
          context.l10n.filterWithTracking,
          context.l10n.filterWithoutTracking,
        ),
        selected: <PresenceFilter>{draft.tracking},
        onSelected: (PresenceFilter value) => onEdit(draft.withTracking(value)),
      ),
      OrderFilterGroup.saleRange => _SaleRange(
        title: title,
        draft: draft,
        min: min,
        max: max,
        onEdit: onEdit,
      ),
    };
  }
}

/// The sale-price window: two boxes, either of which may stand alone.
class _SaleRange extends ConsumerWidget {
  const _SaleRange({
    required this.title,
    required this.draft,
    required this.min,
    required this.max,
    required this.onEdit,
  });

  final String? title;
  final OrderFilterCriteria draft;
  final TextEditingController min;
  final TextEditingController max;
  final ValueChanged<OrderFilterCriteria> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String currency = ref.watch(workspaceCurrencyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (title != null) ...<Widget>[
          Text(
            title!,
            style: context.textTheme3.labelMedium!.semiBold3.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: MoneyField(
                label: context.l10n.filterRangeMin,
                controller: min,
                currency: currency,
                onChanged: (String value) =>
                    onEdit(draft.withMinSale(Money.tryParse(value, currency))),
              ),
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: MoneyField(
                label: context.l10n.filterRangeMax,
                controller: max,
                currency: currency,
                onChanged: (String value) =>
                    onEdit(draft.withMaxSale(Money.tryParse(value, currency))),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The raw statuses, each carrying how many orders ticking it alone would
/// show under the draft's other groups.
class _StatusGroup extends ConsumerWidget {
  const _StatusGroup({
    required this.title,
    required this.draft,
    required this.onEdit,
  });

  final String? title;
  final OrderFilterCriteria draft;
  final ValueChanged<OrderFilterCriteria> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<OrderStatus, int> counts = draft.statusCounts(
      ref.watch(ordersProvider).value ?? const <Order>[],
      now: ref.watch(clockProvider).now(),
    );

    return AppFilterChipGroup<OrderStatus>(
      title: title,
      options: <AppFilterOption<OrderStatus>>[
        for (final OrderStatus status in OrderStatus.values)
          AppFilterOption<OrderStatus>(
            value: status,
            label: OrderStatusLabel.of(context, status),
            count: counts[status],
          ),
      ],
      selected: draft.statuses,
      onSelected: (OrderStatus value) => onEdit(draft.withStatusToggled(value)),
    );
  }
}
