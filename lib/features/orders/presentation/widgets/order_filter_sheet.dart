import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/filters/date_range_filter.dart';
import '../../../../core/filters/presence_filter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/app_filter_chip_group.dart';
import '../../../../core/widgets/app_filter_sheet_actions.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/order_filter_criteria.dart';
import '../../domain/enums/order_deadline_filter.dart';
import '../../domain/enums/order_status.dart';
import '../../providers.dart';
import '../order_filter_label.dart';
import '../order_status_label.dart';

/// Everything Orders can be narrowed by, in one sheet.
///
/// The same shape Inventory's has — a draft the chips edit, written to the
/// screen only when Apply is pressed. See `InventoryFilterSheet` for the rule
/// and its reason.
///
/// **Unlike Inventory's, it repeats the strip's presets as its first group**,
/// and the preset is part of the draft (`docs/rules/SCREENS.md`).
class OrderFilterSheet extends ConsumerStatefulWidget {
  const OrderFilterSheet({super.key});

  /// How much of the screen the sheet takes. The same fraction Inventory's
  /// uses: two sheets a seller opens from neighbouring tabs must not be two
  /// heights.
  static const double heightFactor = 0.85;

  static Future<void> show(BuildContext context) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => const OrderFilterSheet(),
  );

  @override
  ConsumerState<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends ConsumerState<OrderFilterSheet> {
  final TextEditingController _min = TextEditingController();
  final TextEditingController _max = TextEditingController();

  /// What the seller has ticked so far — see `InventoryFilterSheet`. The two
  /// boxes below are the same draft, held as text because that is what a
  /// field edits.
  late OrderFilterCriteria _draft = ref.read(orderCriteriaProvider);

  /// The strip's preset, pending like everything else here.
  late OrderFilter _tab = ref.read(orderFilterProvider);

  @override
  void initState() {
    super.initState();

    // Seeded once, from the same read the draft starts at.
    _min.text = _draft.minSale?.toInputString() ?? '';
    _max.text = _draft.maxSale?.toInputString() ?? '';
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _edit(OrderFilterCriteria next) => setState(() => _draft = next);

  void _selectTab(OrderFilter tab) => setState(() => _tab = tab);

  void _apply() {
    ref.read(orderCriteriaProvider.notifier).apply(_draft, tab: _tab);
    Navigator.of(context).pop();
  }

  /// Empties the draft, the two boxes that are part of it, and the preset.
  void _reset() {
    _min.clear();
    _max.clear();
    setState(() {
      _tab = OrderFilter.all;
      _draft = OrderFilterCriteria.none;
    });
  }

  List<AppFilterOption<PresenceFilter>> _presence(
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
  Widget build(BuildContext context) {
    final OrderFilterCriteria criteria = _draft;
    final String currency = ref.watch(workspaceCurrencyProvider);
    final Map<String, String> marketplaces = ref.watch(
      orderMarketplaceNamesProvider,
    );
    final int pending = _tab == OrderFilter.all
        ? criteria.activeCount
        : criteria.activeCount + 1;

    return SdBottomSheetV3(
      title: context.l10n.filterTitle,
      closeTooltip: context.l10n.commonClose,
      heightFactor: OrderFilterSheet.heightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppFilterChipGroup<OrderFilter>(
                    title: context.l10n.filterShow,
                    options: <AppFilterOption<OrderFilter>>[
                      for (final OrderFilter tab in OrderFilter.values)
                        AppFilterOption<OrderFilter>(
                          value: tab,
                          label: OrderFilterLabel.of(context, tab),
                        ),
                    ],
                    selected: <OrderFilter>{_tab},
                    onSelected: _selectTab,
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<OrderStatus>(
                    title: context.l10n.filterStatus,
                    options: <AppFilterOption<OrderStatus>>[
                      for (final OrderStatus status in OrderStatus.values)
                        AppFilterOption<OrderStatus>(
                          value: status,
                          label: OrderStatusLabel.of(context, status),
                        ),
                    ],
                    selected: criteria.statuses,
                    onSelected: (OrderStatus value) =>
                        _edit(criteria.withStatusToggled(value)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<String>(
                    title: context.l10n.filterMarketplace,
                    options: <AppFilterOption<String>>[
                      for (final MapEntry<String, String> entry
                          in marketplaces.entries)
                        AppFilterOption<String>(
                          value: entry.key,
                          label: entry.value,
                        ),
                    ],
                    selected: criteria.marketplaceIds,
                    onSelected: (String id) =>
                        _edit(criteria.withMarketplaceToggled(id)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<DateRangeFilter>(
                    title: context.l10n.filterOrdered,
                    options: <AppFilterOption<DateRangeFilter>>[
                      for (final DateRangeFilter range
                          in DateRangeFilter.values)
                        AppFilterOption<DateRangeFilter>(
                          value: range,
                          label: range.label(context),
                        ),
                    ],
                    selected: <DateRangeFilter>{criteria.ordered},
                    onSelected: (DateRangeFilter value) =>
                        _edit(criteria.withOrdered(value)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<OrderDeadlineFilter>(
                    title: context.l10n.filterDeadline,
                    options: <AppFilterOption<OrderDeadlineFilter>>[
                      for (final OrderDeadlineFilter deadline
                          in OrderDeadlineFilter.values)
                        AppFilterOption<OrderDeadlineFilter>(
                          value: deadline,
                          label: deadline.label(context),
                        ),
                    ],
                    selected: <OrderDeadlineFilter>{criteria.deadline},
                    onSelected: (OrderDeadlineFilter value) =>
                        _edit(criteria.withDeadline(value)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<PresenceFilter>(
                    title: context.l10n.filterPayout,
                    options: _presence(
                      context.l10n.filterPayoutReceived,
                      context.l10n.filterPayoutAwaiting,
                    ),
                    selected: <PresenceFilter>{criteria.payout},
                    onSelected: (PresenceFilter value) =>
                        _edit(criteria.withPayout(value)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<PresenceFilter>(
                    title: context.l10n.filterTracking,
                    options: _presence(
                      context.l10n.filterWithTracking,
                      context.l10n.filterWithoutTracking,
                    ),
                    selected: <PresenceFilter>{criteria.tracking},
                    onSelected: (PresenceFilter value) =>
                        _edit(criteria.withTracking(value)),
                  ),
                  const AppFilterGroupDivider(),
                  Text(
                    context.l10n.filterSaleRange,
                    style: context.textTheme3.labelMedium!.semiBold3.copyWith(
                      color: context.sdTheme3.textSecondary,
                    ),
                  ),
                  SizedBox(height: SdSpacingConstant.h8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: MoneyField(
                          label: context.l10n.filterRangeMin,
                          controller: _min,
                          currency: currency,
                          onChanged: (String value) => _edit(
                            criteria.withMinSale(
                              Money.tryParse(value, currency),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: SdSpacingConstant.w12),
                      Expanded(
                        child: MoneyField(
                          label: context.l10n.filterRangeMax,
                          controller: _max,
                          currency: currency,
                          onChanged: (String value) => _edit(
                            criteria.withMaxSale(
                              Money.tryParse(value, currency),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: SdContentPaddingV3.pinnedActionsGap),
          AppFilterSheetActions(
            // The draft's groups plus the preset, which this sheet offers.
            pending: pending,
            onReset: _reset,
            onApply: _apply,
          ),
        ],
      ),
    );
  }
}
