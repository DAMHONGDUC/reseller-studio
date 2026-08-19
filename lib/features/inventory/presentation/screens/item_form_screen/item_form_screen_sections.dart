part of 'item_form_screen.dart';

/// A titled group of fields inside one card.
///
/// Grouping rather than one flat column: the form asks about five different
/// subjects, and a seller filling in only the pricing should be able to find
/// where it starts and stops.
class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: context.textTheme3.titleSmall!.semiBold3.copyWith(
          color: context.sdTheme3.textPrimary,
        ),
      ),
      SizedBox(height: SdSpacingConstant.h8),
      SdCardV3(
        child: Column(
          children: <Widget>[
            for (int i = 0; i < children.length; i++) ...<Widget>[
              children[i],
              if (i != children.length - 1)
                SizedBox(height: SdSpacingConstant.h16),
            ],
          ],
        ),
      ),
    ],
  );
}

/// The condition grades resellers actually use in listings.
class _ConditionField extends ConsumerWidget {
  const _ConditionField({required this.state});

  final ItemFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PickerField(
    label: context.l10n.itemCondition,
    icon: Symbols.grade_rounded,
    value: state.condition == null
        ? null
        : ItemConditionLabel.of(context, state.condition!),
    onTap: () async {
      final ItemCondition? picked = await OptionPickerSheet.show<ItemCondition>(
        context,
        title: context.l10n.itemCondition,
        selected: state.condition,
        options: ItemCondition.values
            .map(
              (ItemCondition condition) => PickerOption<ItemCondition>(
                value: condition,
                label: ItemConditionLabel.of(context, condition),
              ),
            )
            .toList(),
      );

      if (picked == null) return;

      ref.read(itemFormControllerProvider.notifier).selectCondition(picked);
    },
  );
}

class _CategoryField extends ConsumerWidget {
  const _CategoryField({required this.state});

  final ItemFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ItemCategory> categories =
        ref.watch(categoriesProvider).value ?? const <ItemCategory>[];
    final Map<String, String> names = ref.watch(categoryNamesProvider);

    return PickerField(
      label: context.l10n.commonCategory,
      icon: Symbols.category_rounded,
      value: state.categoryId == null ? null : names[state.categoryId],
      placeholder: categories.isEmpty
          ? context.l10n.itemCategoryEmptyHint
          : null,
      onTap: categories.isEmpty
          ? () => SdSnackBarUtilsV3.info(
              context,
              context.l10n.itemAddCategoryFirst,
            )
          : () async {
              final String? picked = await OptionPickerSheet.show<String>(
                context,
                title: context.l10n.commonCategory,
                selected: state.categoryId,
                options: categories
                    .map(
                      (ItemCategory category) => PickerOption<String>(
                        value: category.id,
                        label: category.name,
                      ),
                    )
                    .toList(),
              );

              if (picked == null) return;

              ref
                  .read(itemFormControllerProvider.notifier)
                  .selectCategory(picked);
            },
    );
  }
}

class _LocationField extends ConsumerWidget {
  const _LocationField({required this.state});

  final ItemFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<StorageLocation> locations =
        ref.watch(locationsProvider).value ?? const <StorageLocation>[];
    final Map<String, String> paths = ref.watch(locationPathsProvider);

    return PickerField(
      label: context.l10n.commonLocation,
      icon: Symbols.shelves,
      value: state.locationId == null ? null : paths[state.locationId],
      placeholder: locations.isEmpty
          ? context.l10n.itemLocationEmptyHint
          : null,
      onTap: locations.isEmpty
          ? () => SdSnackBarUtilsV3.info(
              context,
              context.l10n.itemAddLocationFirst,
            )
          : () async {
              final String? picked = await OptionPickerSheet.show<String>(
                context,
                title: context.l10n.commonLocation,
                selected: state.locationId,
                options: locations
                    .map(
                      (StorageLocation location) => PickerOption<String>(
                        value: location.id,
                        label: paths[location.id] ?? location.name,
                        caption: LocationKindLabel.of(context, location.kind),
                      ),
                    )
                    .toList(),
              );

              if (picked == null) return;

              ref
                  .read(itemFormControllerProvider.notifier)
                  .selectLocation(picked);
            },
    );
  }
}

class _SourceField extends ConsumerWidget {
  const _SourceField({required this.state});

  final ItemFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Source> sources =
        ref.watch(sourcesProvider).value ?? const <Source>[];
    final Map<String, String> names = ref.watch(sourceNamesProvider);

    return PickerField(
      label: context.l10n.commonSource,
      icon: Symbols.storefront_rounded,
      value: state.sourceId == null ? null : names[state.sourceId],
      placeholder: sources.isEmpty ? context.l10n.itemSourceEmptyHint : null,
      onTap: sources.isEmpty
          ? () =>
                SdSnackBarUtilsV3.info(context, context.l10n.itemAddSourceFirst)
          : () async {
              final String? picked = await OptionPickerSheet.show<String>(
                context,
                title: context.l10n.commonSource,
                selected: state.sourceId,
                options: sources
                    .map(
                      (Source source) => PickerOption<String>(
                        value: source.id,
                        label: source.name,
                      ),
                    )
                    .toList(),
              );

              if (picked == null) return;

              ref
                  .read(itemFormControllerProvider.notifier)
                  .selectSource(picked);
            },
    );
  }
}

class _PurchaseDateField extends ConsumerWidget {
  const _PurchaseDateField({required this.state});

  final ItemFormState state;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();

    return PickerField(
      label: context.l10n.itemPurchaseDate,
      icon: Symbols.calendar_month_rounded,
      value: state.purchaseDate == null
          ? null
          : DateTimeUtils.mediumDate(
              state.purchaseDate!,
              locale: context.localeTag,
            ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: state.purchaseDate ?? now,
          firstDate: DateTime(now.year - DatePickerConstant.taxRecordYearsBack),
          // No future purchase dates: a receipt cannot be from next month, and
          // one filed there breaks every period report it lands in.
          lastDate: now,
        );

        if (picked == null) return;

        ref
            .read(itemFormControllerProvider.notifier)
            .selectPurchaseDate(picked);
      },
    );
  }
}
