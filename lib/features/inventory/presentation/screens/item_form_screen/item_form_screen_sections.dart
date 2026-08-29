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

/// The item's state, editable — four tags, each wearing its own colour.
///
/// **Tags rather than a picker sheet** — owner's rule. There are four states
/// and they are the answer to one question, so hiding them behind a row that
/// opens a sheet costs two taps to see what the choices even are. Laid out,
/// the seller reads the whole vocabulary at once.
///
/// **Switching is free** — owner's rule, and it is the newest one here. No
/// requirement is checked and no move is refused: the picker is where a
/// seller corrects what the app got wrong, and a correction that argues back
/// is the thing they came to fix. What the *verbs* do is unchanged —
/// `ItemTransition.check` still gates Mark as sold and the bulk paths, which
/// is where a missing price actually matters.
///
/// Setting `sold` still empties the count, because sold means sold out
/// however it was reached, and it writes **no order**: revenue and profit are
/// read from orders (hard rule 3), so a sale that has to show up in the
/// figures is recorded through Mark as sold.
class _StatusField extends ConsumerWidget {
  const _StatusField({required this.state});

  final ItemFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _TagGroupField(
    label: context.l10n.itemStatus,
    children: <Widget>[
      for (final ItemStatus status in ItemStatus.values)
        SdTagV3(
          label: ItemStatusLabel.of(context, status),
          color: status.color(context),
          selected: state.status == status,
          onSelected: () => ref
              .read(itemFormControllerProvider.notifier)
              .selectStatus(status),
        ),
    ],
  );
}

/// The label and the wrap that every tag group on this form shares.
///
/// Extracted on its second use, which is the trigger the rules name: status
/// and condition ask the same shape of question and must not answer it two
/// ways.
///
/// **Full width and left-aligned**: `_FormSection` centres what it is given,
/// so a group that sized to its tags would sit indented while every typed row
/// beside it starts at the card's edge.
class _TagGroupField extends StatelessWidget {
  const _TagGroupField({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // The same label widget the typed and picked rows use, so one form
        // cannot label its fields three ways.
        SdFieldLabelV3(label: label),
        SizedBox(height: SdSpacingConstant.h6),
        Wrap(
          spacing: SdSpacingConstant.w8,
          runSpacing: SdSpacingConstant.h8,
          children: children,
        ),
      ],
    ),
  );
}

/// The condition grades resellers actually use in listings.
///
/// **Tags, like the status above** — owner's rule. Seven grades behind a sheet
/// is a list nobody opens, and the grade is what a buyer reads first on every
/// marketplace.
///
/// **Each grade has its own colour**, ordered best to worst, so the set reads
/// as a scale rather than seven equal options.
class _ConditionField extends ConsumerWidget {
  const _ConditionField({required this.state});

  final ItemFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _TagGroupField(
    label: context.l10n.itemCondition,
    children: <Widget>[
      for (final ItemCondition condition in ItemCondition.values)
        SdTagV3(
          label: ItemConditionLabel.of(context, condition),
          color: condition.color(context),
          selected: state.condition == condition,
          onSelected: () => ref
              .read(itemFormControllerProvider.notifier)
              .selectCondition(condition),
        ),
    ],
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
      icon: AppIconConstant.category,
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
      icon: AppIconConstant.shelves,
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
      icon: AppIconConstant.storefront,
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
      icon: AppIconConstant.calendarMonth,
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
