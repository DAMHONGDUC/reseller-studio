import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/filters/date_range_filter.dart';
import '../../../../core/filters/presence_filter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/app_active_filter_bar.dart';
import '../../../../core/widgets/app_filter_chip_group.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../workspace/providers.dart';
import '../../domain/entities/order_filter_criteria.dart';
import '../../domain/enums/order_deadline_filter.dart';
import '../../domain/enums/order_status.dart';
import '../../providers.dart';
import '../order_status_label.dart';

/// Everything Orders can be narrowed by, in one sheet.
///
/// The same shape Inventory's has — applied as it is tapped, with the primary
/// button carrying the count instead of committing anything. See
/// `InventoryFilterSheet` for why there is no Apply.
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

  @override
  void initState() {
    super.initState();

    final OrderFilterCriteria criteria = ref.read(orderCriteriaProvider);

    // Seeded once — see `InventoryFilterSheet`.
    _min.text = criteria.minSale?.toInputString() ?? '';
    _max.text = criteria.maxSale?.toInputString() ?? '';
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _reset() {
    ref.read(orderCriteriaProvider.notifier).reset();
    _min.clear();
    _max.clear();
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
    final OrderFilterCriteria criteria = ref.watch(orderCriteriaProvider);
    final OrderCriteriaController controller = ref.read(
      orderCriteriaProvider.notifier,
    );
    final String currency = ref.watch(workspaceCurrencyProvider);
    final int shown = ref.watch(visibleOrdersProvider).length;
    final Map<String, String> marketplaces = ref.watch(
      orderMarketplaceNamesProvider,
    );
    final double groupGap = SdSpacingConstant.h20;

    return SdBottomSheetV3(
      title: context.l10n.filterTitle,
      closeTooltip: context.l10n.commonClose,
      heightFactor: OrderFilterSheet.heightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppActiveFilterBar(
            count: ref.watch(orderActiveFilterCountProvider),
            onReset: _reset,
            gutter: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
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
                    onSelected: controller.toggleStatus,
                  ),
                  SizedBox(height: groupGap),
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
                    onSelected: controller.toggleMarketplace,
                  ),
                  SizedBox(height: groupGap),
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
                    onSelected: controller.setOrdered,
                  ),
                  SizedBox(height: groupGap),
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
                    onSelected: controller.setDeadline,
                  ),
                  SizedBox(height: groupGap),
                  AppFilterChipGroup<PresenceFilter>(
                    title: context.l10n.filterPayout,
                    options: _presence(
                      context.l10n.filterPayoutReceived,
                      context.l10n.filterPayoutAwaiting,
                    ),
                    selected: <PresenceFilter>{criteria.payout},
                    onSelected: controller.setPayout,
                  ),
                  SizedBox(height: groupGap),
                  AppFilterChipGroup<PresenceFilter>(
                    title: context.l10n.filterTracking,
                    options: _presence(
                      context.l10n.filterWithTracking,
                      context.l10n.filterWithoutTracking,
                    ),
                    selected: <PresenceFilter>{criteria.tracking},
                    onSelected: controller.setTracking,
                  ),
                  SizedBox(height: groupGap),
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
                          onChanged: (String value) => controller.setMinSale(
                            Money.tryParse(value, currency),
                          ),
                        ),
                      ),
                      SizedBox(width: SdSpacingConstant.w12),
                      Expanded(
                        child: MoneyField(
                          label: context.l10n.filterRangeMax,
                          controller: _max,
                          currency: currency,
                          onChanged: (String value) => controller.setMaxSale(
                            Money.tryParse(value, currency),
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
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            expand: true,
            label: context.l10n.filterShowOrders(shown),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
