import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/filters/date_range_filter.dart';
import '../../../../core/filters/presence_filter.dart';
import '../../../../core/widgets/app_active_filter_bar.dart';
import '../../../../core/widgets/app_filter_chip_group.dart';
import '../../../sourcing/providers.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_filter_criteria.dart';
import '../../domain/enums/item_status.dart';
import '../../item_filter_constant.dart';
import '../../providers.dart';

/// Everything Inventory can be narrowed by, in one sheet.
///
/// **It applies as it is tapped; there is no Apply button.** The list behind
/// the sheet is the answer, and the primary button says how many rows are left
/// rather than committing anything — a seller who ticks a category and sees
/// the count move knows immediately whether the filter was the one they meant.
///
/// **The strip's five tabs are deliberately not repeated here.** They are one
/// tap away above the list; what is here is the vocabulary that has nowhere
/// else to be asked — including a status group, because `archived` and the
/// seller's own condition grades are not tabs.
class InventoryFilterSheet extends ConsumerWidget {
  const InventoryFilterSheet({super.key});

  /// How much of the screen the sheet takes. Fixed rather than sized to its
  /// groups: the content grows with the seller's own categories and locations,
  /// so a sheet that fitted it would be a different height in every business.
  static const double heightFactor = 0.85;

  static Future<void> show(BuildContext context) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => const InventoryFilterSheet(),
  );

  /// The three states of "does it have one", worded for what is being asked.
  ///
  /// Every group the sheet offers is now a set of chips, so the sheet holds
  /// no text fields and therefore no controllers — which is why it is a plain
  /// `ConsumerWidget` again.
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

  /// A group of records plus the chip for the items that name none of them.
  List<AppFilterOption<String>> _byId(
    BuildContext context,
    Map<String, String> namesById,
  ) =>
      <AppFilterOption<String>>[
        for (final MapEntry<String, String> entry in namesById.entries)
          AppFilterOption<String>(value: entry.key, label: entry.value),
        AppFilterOption<String>(
          value: ItemFilterConstant.unassignedId,
          label: context.l10n.filterUnassigned,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ItemFilterCriteria criteria = ref.watch(inventoryCriteriaProvider);
    final InventoryCriteriaController controller = ref.read(
      inventoryCriteriaProvider.notifier,
    );
    final int shown = ref.watch(visibleItemsProvider).length;
    final Map<String, String> categories = <String, String>{
      for (final ItemCategory category
          in ref.watch(categoriesProvider).value ?? const <ItemCategory>[])
        category.id: category.name,
    };
    final double groupGap = SdSpacingConstant.h20;

    return SdBottomSheetV3(
      title: context.l10n.filterTitle,
      closeTooltip: context.l10n.commonClose,
      heightFactor: InventoryFilterSheet.heightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppActiveFilterBar(
            count: ref.watch(inventoryActiveFilterCountProvider),
            onReset: ref.read(inventoryCriteriaProvider.notifier).reset,
            gutter: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppFilterChipGroup<ItemStatus>(
                    title: context.l10n.filterStatus,
                    options: <AppFilterOption<ItemStatus>>[
                      for (final ItemStatus status in ItemStatus.values)
                        AppFilterOption<ItemStatus>(
                          value: status,
                          label: status.label(context),
                        ),
                    ],
                    selected: criteria.statuses,
                    onSelected: controller.toggleStatus,
                  ),
                  SizedBox(height: groupGap),
                  AppFilterChipGroup<ItemCondition>(
                    title: context.l10n.itemCondition,
                    options: <AppFilterOption<ItemCondition>>[
                      for (final ItemCondition condition
                          in ItemCondition.values)
                        AppFilterOption<ItemCondition>(
                          value: condition,
                          label: condition.label(context),
                        ),
                    ],
                    selected: criteria.conditions,
                    onSelected: controller.toggleCondition,
                  ),
                  SizedBox(height: groupGap),
                  AppFilterChipGroup<String>(
                    title: context.l10n.filterCategory,
                    options: _byId(context, categories),
                    selected: criteria.categoryIds,
                    onSelected: controller.toggleCategory,
                  ),
                  SizedBox(height: groupGap),
                  AppFilterChipGroup<String>(
                    title: context.l10n.filterLocation,
                    options: _byId(context, ref.watch(locationPathsProvider)),
                    selected: criteria.locationIds,
                    onSelected: controller.toggleLocation,
                  ),
                  SizedBox(height: groupGap),
                  AppFilterChipGroup<String>(
                    title: context.l10n.filterSource,
                    options: _byId(context, ref.watch(sourceNamesProvider)),
                    selected: criteria.sourceIds,
                    onSelected: controller.toggleSource,
                  ),
                  SizedBox(height: groupGap),
                  AppFilterChipGroup<PresenceFilter>(
                    title: context.l10n.filterPhotos,
                    options: _presence(
                      context,
                      context.l10n.filterWithPhotos,
                      context.l10n.filterWithoutPhotos,
                    ),
                    selected: <PresenceFilter>{criteria.photos},
                    onSelected: controller.setPhotos,
                  ),
                  SizedBox(height: groupGap),
                  AppFilterChipGroup<PresenceFilter>(
                    title: context.l10n.filterCost,
                    options: _presence(
                      context,
                      context.l10n.filterCostRecorded,
                      context.l10n.filterCostMissing,
                    ),
                    selected: <PresenceFilter>{criteria.cost},
                    onSelected: controller.setCost,
                  ),
                  SizedBox(height: groupGap),
                  AppFilterChipGroup<PresenceFilter>(
                    title: context.l10n.filterListed,
                    options: _presence(
                      context,
                      context.l10n.filterEverListed,
                      context.l10n.filterNeverListed,
                    ),
                    selected: <PresenceFilter>{criteria.listed},
                    onSelected: controller.setListed,
                  ),
                  SizedBox(height: groupGap),
                  AppFilterChipGroup<DateRangeFilter>(
                    title: context.l10n.filterAdded,
                    options: <AppFilterOption<DateRangeFilter>>[
                      for (final DateRangeFilter range
                          in DateRangeFilter.values)
                        AppFilterOption<DateRangeFilter>(
                          value: range,
                          label: range.label(context),
                        ),
                    ],
                    selected: <DateRangeFilter>{criteria.added},
                    onSelected: controller.setAdded,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: SdContentPaddingV3.pinnedActionsGap),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            expand: true,
            // The count, not "Apply": nothing is pending, and a seller who can
            // see there are no rows left knows to loosen a chip before closing.
            label: context.l10n.filterShowItems(shown),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
