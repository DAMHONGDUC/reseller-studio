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

  /// Turns `newWithTags` into `New with tags`.
  ///
  /// Derived rather than a switch with nine cases: the enum is the marketplace
  /// vocabulary, and a hand-written label per case is nine more places to
  /// update when a tenth grade arrives.
  static String label(ItemCondition condition) {
    final String spaced = condition.name.replaceAllMapped(
      RegExp('[A-Z]'),
      (Match match) => ' ${match.group(0)!.toLowerCase()}',
    );

    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => PickerField(
    label: 'Condition',
    icon: Symbols.grade_rounded,
    value: state.condition == null ? null : label(state.condition!),
    onTap: () async {
      final ItemCondition? picked = await OptionPickerSheet.show<ItemCondition>(
        context,
        title: 'Condition',
        selected: state.condition,
        options: ItemCondition.values
            .map(
              (ItemCondition condition) => PickerOption<ItemCondition>(
                value: condition,
                label: label(condition),
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
      label: 'Category',
      icon: Symbols.category_rounded,
      value: state.categoryId == null ? null : names[state.categoryId],
      placeholder: categories.isEmpty ? 'None yet — add one in More' : 'Not set',
      onTap: categories.isEmpty
          ? () => SdSnackBarUtilsV3.info(
              context,
              'Add a category first: More → Categories',
            )
          : () async {
              final String? picked = await OptionPickerSheet.show<String>(
                context,
                title: 'Category',
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
      label: 'Location',
      icon: Symbols.shelves,
      value: state.locationId == null ? null : paths[state.locationId],
      placeholder: locations.isEmpty
          ? 'None yet — add one in Locations'
          : 'Not set',
      onTap: locations.isEmpty
          ? () => SdSnackBarUtilsV3.info(
              context,
              'Add a location first: More → Locations',
            )
          : () async {
              final String? picked = await OptionPickerSheet.show<String>(
                context,
                title: 'Location',
                selected: state.locationId,
                options: locations
                    .map(
                      (StorageLocation location) => PickerOption<String>(
                        value: location.id,
                        label: paths[location.id] ?? location.name,
                        caption: location.kind.name,
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
      label: 'Source',
      icon: Symbols.storefront_rounded,
      value: state.sourceId == null ? null : names[state.sourceId],
      placeholder: sources.isEmpty ? 'None yet — add one in Sourcing' : 'Not set',
      onTap: sources.isEmpty
          ? () => SdSnackBarUtilsV3.info(
              context,
              'Add a source first: More → Sourcing',
            )
          : () async {
              final String? picked = await OptionPickerSheet.show<String>(
                context,
                title: 'Source',
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

  /// How far back the date picker opens.
  ///
  /// Five years covers the tax records a reseller keeps; a picker that opens
  /// at 1970 makes reaching last Tuesday a scroll.
  static const int pickerYearsBack = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = DateTime.now();

    return PickerField(
      label: 'Purchase date',
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
          firstDate: DateTime(now.year - pickerYearsBack),
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
