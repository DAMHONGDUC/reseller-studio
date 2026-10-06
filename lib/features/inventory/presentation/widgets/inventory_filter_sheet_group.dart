part of 'inventory_filter_sheet.dart';

/// One group of the sheet, edited on the draft.
class _ItemFilterGroupView extends ConsumerWidget {
  const _ItemFilterGroupView({
    required this.group,
    required this.draft,
    required this.showTitle,
    required this.onEdit,
  });

  final ItemFilterGroup group;
  final ItemFilterCriteria draft;
  final bool showTitle;
  final ValueChanged<ItemFilterCriteria> onEdit;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final String? title = showTitle ? group.label(context) : null;

    return switch (group) {
      ItemFilterGroup.status => _StatusGroup(
        title: title,
        draft: draft,
        onEdit: onEdit,
      ),
      ItemFilterGroup.condition => AppFilterChipGroup<ItemCondition>(
        title: title,
        options: <AppFilterOption<ItemCondition>>[
          for (final ItemCondition condition in ItemCondition.values)
            AppFilterOption<ItemCondition>(
              value: condition,
              label: condition.label(context),
            ),
        ],
        selected: draft.conditions,
        onSelected: (ItemCondition value) =>
            onEdit(draft.withConditionToggled(value)),
      ),
      ItemFilterGroup.category => AppFilterChipGroup<String>(
        title: title,
        options: _byId(context, <String, String>{
          for (final ItemCategory category
              in ref.watch(categoriesProvider).value ?? const <ItemCategory>[])
            category.id: category.name,
        }),
        selected: draft.categoryIds,
        onSelected: (String id) => onEdit(draft.withCategoryToggled(id)),
      ),
      ItemFilterGroup.location => AppFilterChipGroup<String>(
        title: title,
        options: _byId(context, ref.watch(locationPathsProvider)),
        selected: draft.locationIds,
        onSelected: (String id) => onEdit(draft.withLocationToggled(id)),
      ),
      ItemFilterGroup.source => AppFilterChipGroup<String>(
        title: title,
        options: _byId(context, ref.watch(sourceNamesProvider)),
        selected: draft.sourceIds,
        onSelected: (String id) => onEdit(draft.withSourceToggled(id)),
      ),
      ItemFilterGroup.photos => AppFilterChipGroup<PresenceFilter>(
        title: title,
        options: _presence(
          context,
          context.l10n.filterWithPhotos,
          context.l10n.filterWithoutPhotos,
        ),
        selected: <PresenceFilter>{draft.photos},
        onSelected: (PresenceFilter value) => onEdit(draft.withPhotos(value)),
      ),
      ItemFilterGroup.cost => AppFilterChipGroup<PresenceFilter>(
        title: title,
        options: _presence(
          context,
          context.l10n.filterCostRecorded,
          context.l10n.filterCostMissing,
        ),
        selected: <PresenceFilter>{draft.cost},
        onSelected: (PresenceFilter value) => onEdit(draft.withCost(value)),
      ),
      ItemFilterGroup.listed => AppFilterChipGroup<PresenceFilter>(
        title: title,
        options: _presence(
          context,
          context.l10n.filterEverListed,
          context.l10n.filterNeverListed,
        ),
        selected: <PresenceFilter>{draft.listed},
        onSelected: (PresenceFilter value) => onEdit(draft.withListed(value)),
      ),
      ItemFilterGroup.added => AppFilterChipGroup<DateRangeFilter>(
        title: title,
        options: <AppFilterOption<DateRangeFilter>>[
          for (final DateRangeFilter range in DateRangeFilter.values)
            AppFilterOption<DateRangeFilter>(
              value: range,
              label: range.label(context),
            ),
        ],
        selected: <DateRangeFilter>{draft.added},
        onSelected: (DateRangeFilter value) => onEdit(draft.withAdded(value)),
      ),
    };
  }
}

/// Status, Stale among the options, each carrying how many rows ticking it
/// alone would show under the draft's other groups.
class _StatusGroup extends ConsumerWidget {
  const _StatusGroup({
    required this.title,
    required this.draft,
    required this.onEdit,
  });

  final String? title;
  final ItemFilterCriteria draft;
  final ValueChanged<ItemFilterCriteria> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<ItemStatusFilter, int> counts = draft.statusCounts(
      ref.watch(itemsProvider).value ?? const <Item>[],
      query: ref.watch(inventorySearchProvider),
      now: ref.watch(clockProvider).now(),
    );

    return AppFilterChipGroup<ItemStatusFilter>(
      title: title,
      options: <AppFilterOption<ItemStatusFilter>>[
        for (final ItemStatusFilter status in ItemStatusFilter.values)
          AppFilterOption<ItemStatusFilter>(
            value: status,
            label: status.label(context),
            count: counts[status],
          ),
      ],
      selected: draft.statuses,
      onSelected: (ItemStatusFilter value) =>
          onEdit(draft.withStatusToggled(value)),
    );
  }
}
