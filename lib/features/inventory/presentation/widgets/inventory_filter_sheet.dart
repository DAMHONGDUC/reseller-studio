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
/// **Nothing is applied until Apply is pressed** — owner's rule, and it
/// **reverses "it applies as it is tapped"**. The chips edit a draft this
/// sheet holds; the list behind it does not move while the seller is still
/// deciding, and closing the sheet any other way leaves the list exactly as
/// they found it.
///
/// **Reset clears the draft, not the screen.** It is the same button, but it
/// now empties what is pending — the strip behind the sheet has its own Reset
/// for the filters that are actually on, and that one still clears the tab
/// with them.
///
/// **The strip's five tabs are deliberately not repeated here.** They are one
/// tap away above the list; what is here is the vocabulary that has nowhere
/// else to be asked — including a status group, because `archived` and the
/// seller's own condition grades are not tabs.
class InventoryFilterSheet extends ConsumerStatefulWidget {
  const InventoryFilterSheet({super.key});

  /// How much of the screen the sheet takes. Fixed rather than sized to its
  /// groups: the content grows with the seller's own categories and locations,
  /// so a sheet that fitted it would be a different height in every business.
  static const double heightFactor = 0.85;

  static Future<void> show(BuildContext context) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => const InventoryFilterSheet(),
  );

  @override
  ConsumerState<InventoryFilterSheet> createState() =>
      _InventoryFilterSheetState();
}

class _InventoryFilterSheetState extends ConsumerState<InventoryFilterSheet> {
  /// What the seller has ticked so far. Seeded from what is applied, once:
  /// the sheet opens on the filters the list is already under, and every tap
  /// after that moves this and nothing else.
  late ItemFilterCriteria _draft = ref.read(inventoryCriteriaProvider);

  void _edit(ItemFilterCriteria next) => setState(() => _draft = next);

  void _apply() {
    ref.read(inventoryCriteriaProvider.notifier).apply(_draft);
    Navigator.of(context).pop();
  }

  /// The three states of "does it have one", worded for what is being asked.
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
  ) => <AppFilterOption<String>>[
    for (final MapEntry<String, String> entry in namesById.entries)
      AppFilterOption<String>(value: entry.key, label: entry.value),
    AppFilterOption<String>(
      value: ItemFilterConstant.unassignedId,
      label: context.l10n.filterUnassigned,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ItemFilterCriteria criteria = _draft;
    final Map<String, String> categories = <String, String>{
      for (final ItemCategory category
          in ref.watch(categoriesProvider).value ?? const <ItemCategory>[])
        category.id: category.name,
    };

    return SdBottomSheetV3(
      title: context.l10n.filterTitle,
      closeTooltip: context.l10n.commonClose,
      heightFactor: InventoryFilterSheet.heightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppActiveFilterBar(
            // The draft's own groups, and not the tab: the sheet does not
            // offer the tab, so a number counting it could not be made true
            // by the Reset beside it.
            count: criteria.activeCount,
            onReset: () => _edit(ItemFilterCriteria.none),
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
                    onSelected: (ItemStatus value) =>
                        _edit(criteria.withStatusToggled(value)),
                  ),
                  const AppFilterGroupDivider(),
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
                    onSelected: (ItemCondition value) =>
                        _edit(criteria.withConditionToggled(value)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<String>(
                    title: context.l10n.filterCategory,
                    options: _byId(context, categories),
                    selected: criteria.categoryIds,
                    onSelected: (String id) =>
                        _edit(criteria.withCategoryToggled(id)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<String>(
                    title: context.l10n.filterLocation,
                    options: _byId(context, ref.watch(locationPathsProvider)),
                    selected: criteria.locationIds,
                    onSelected: (String id) =>
                        _edit(criteria.withLocationToggled(id)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<String>(
                    title: context.l10n.filterSource,
                    options: _byId(context, ref.watch(sourceNamesProvider)),
                    selected: criteria.sourceIds,
                    onSelected: (String id) =>
                        _edit(criteria.withSourceToggled(id)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<PresenceFilter>(
                    title: context.l10n.filterPhotos,
                    options: _presence(
                      context,
                      context.l10n.filterWithPhotos,
                      context.l10n.filterWithoutPhotos,
                    ),
                    selected: <PresenceFilter>{criteria.photos},
                    onSelected: (PresenceFilter value) =>
                        _edit(criteria.withPhotos(value)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<PresenceFilter>(
                    title: context.l10n.filterCost,
                    options: _presence(
                      context,
                      context.l10n.filterCostRecorded,
                      context.l10n.filterCostMissing,
                    ),
                    selected: <PresenceFilter>{criteria.cost},
                    onSelected: (PresenceFilter value) =>
                        _edit(criteria.withCost(value)),
                  ),
                  const AppFilterGroupDivider(),
                  AppFilterChipGroup<PresenceFilter>(
                    title: context.l10n.filterListed,
                    options: _presence(
                      context,
                      context.l10n.filterEverListed,
                      context.l10n.filterNeverListed,
                    ),
                    selected: <PresenceFilter>{criteria.listed},
                    onSelected: (PresenceFilter value) =>
                        _edit(criteria.withListed(value)),
                  ),
                  const AppFilterGroupDivider(),
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
                    onSelected: (DateRangeFilter value) =>
                        _edit(criteria.withAdded(value)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: SdContentPaddingV3.pinnedActionsGap),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            expand: true,
            // "Apply", not a count: the number of rows left is a fact about a
            // filter that has been applied, and this button is what applies
            // one.
            label: context.l10n.filterApply,
            onPressed: _apply,
          ),
        ],
      ),
    );
  }
}
