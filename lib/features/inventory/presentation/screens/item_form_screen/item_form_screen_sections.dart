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

/// The item's state, editable — four radios, each wearing its own colour.
///
/// **Radios rather than a picker sheet** — owner's rule. There are four
/// states and they are the answer to one question, so hiding them behind a
/// row that opens a sheet costs two taps to see what the choices even are.
/// Laid out, the seller reads the whole vocabulary at once.
///
/// **Each option carries the colour of its badge** (`ItemStatusLabel.color`),
/// so the chosen radio and the tag on the card are visibly the same thing.
/// Colour is never the only signal: the label is spelled out and the radio is
/// filled.
///
/// **Sold is offered too** — owner's rule. It records that the stock is gone
/// and empties the count with it, and it writes no order: revenue and profit
/// are still read from orders (hard rule 3), so a sale that should show up in
/// the figures is recorded through Mark as sold instead.
///
/// A refused move says which requirement is missing rather than going quiet,
/// the same way the actions sheet does.
class _StatusField extends ConsumerWidget {
  const _StatusField({
    required this.state,
    required this.quantity,
    required this.askingPrice,
  });

  final ItemFormState state;

  /// The boxes as they are right now, so a price typed a second ago counts.
  final TextEditingController quantity;
  final TextEditingController askingPrice;

  void _pick(BuildContext context, WidgetRef ref, ItemStatus status) {
    final ItemFormController form = ref.read(
      itemFormControllerProvider.notifier,
    );
    final ItemTransitionCheck check = form.checkStatus(
      status,
      quantity: quantity.text,
      askingPrice: askingPrice.text,
    );

    if (!check.isAllowed) {
      SdSnackBarUtilsV3.error(
        context,
        ItemBlockPresenter.messages(context, check.blocks),
      );

      return;
    }

    form.selectStatus(status);
  }

  // Full width and left-aligned: `_FormSection` centres what it is given, so
  // a group that sizes to its chips would sit indented while every typed row
  // beside it starts at the card's edge.
  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // The same label widget the typed and picked rows use, so one form
        // cannot label its fields three ways.
        SdFieldLabelV3(label: context.l10n.itemStatus),
        SizedBox(height: SdSpacingConstant.h6),
        Wrap(
          spacing: SdSpacingConstant.w8,
          runSpacing: SdSpacingConstant.h8,
          children: <Widget>[
            for (final ItemStatus status in ItemStatus.values)
              _StatusOption(
                status: status,
                isSelected: state.status == status,
                onTap: () => _pick(context, ref, status),
              ),
          ],
        ),
      ],
    ),
  );
}

/// One radio in that group.
class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final ItemStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  /// How much of the status colour the chosen option keeps behind it. The
  /// same strength `SdBadgeV3` fills with, so the radio and the tag on the
  /// card read as one colour rather than two versions of it.
  static const double selectedFillOpacity = SdBadgeV3.fillOpacity;

  @override
  Widget build(BuildContext context) {
    final Color tint = ItemStatusLabel.color(context, status);
    final Color foreground = isSelected ? tint : context.sdTheme3.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: SdRadiusV3.chipAll,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w12,
          vertical: SdSpacingConstant.h8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? tint.withValues(alpha: selectedFillOpacity)
              : Colors.transparent,
          borderRadius: SdRadiusV3.chipAll,
          border: Border.all(
            color: isSelected ? tint : context.sdTheme3.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SdIconV3(
              isSelected
                  ? AppIconConstant.radioButtonChecked
                  : AppIconConstant.radioButtonUnchecked,
              size: SdIconV3.smallSize,
              color: foreground,
            ),
            SizedBox(width: SdSpacingConstant.w6),
            Text(
              ItemStatusLabel.of(context, status),
              style: context.textTheme3.bodySmall!.semiBold3.copyWith(
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The condition grades resellers actually use in listings./// The condition grades resellers actually use in listings.
class _ConditionField extends ConsumerWidget {
  const _ConditionField({required this.state});

  final ItemFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PickerField(
    label: context.l10n.itemCondition,
    icon: AppIconConstant.grade,
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
