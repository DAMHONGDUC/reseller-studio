import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/constants/date_picker_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../../core/widgets/picker_field.dart';
import '../../../sourcing/domain/entities/source.dart';
import '../../../sourcing/providers.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/storage_location.dart';
import '../../domain/enums/item_status.dart';
import '../../item_label.dart';
import '../../providers.dart';

/// The fields that ask an item's non-typed questions.
///
/// **Extracted because two screens ask them.** The Add Item form owns them
/// while creating; the detail screen's editable sections own them afterwards
/// (`docs/rules/SCREENS.md`). Each takes its current value and a callback and
/// knows no controller, so neither screen can answer the same question a
/// different way.

/// The label and the wrap every tag group shares.
///
/// **Full width and left-aligned**: a card centres what it is given, so a
/// group that sized to its tags would sit indented while every typed row
/// beside it starts at the card's edge.
class ItemTagGroupField extends StatelessWidget {
  const ItemTagGroupField({
    required this.label,
    required this.children,
    super.key,
  });

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
/// **Tags, not a sheet** — owner's rule. Seven grades behind a picker is a
/// list nobody opens, and the grade is what a buyer reads first on every
/// marketplace. Each wears its own colour, ordered best to worst, so the set
/// reads as a scale rather than seven equal options.
class ItemConditionField extends StatelessWidget {
  const ItemConditionField({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ItemCondition? selected;
  final ValueChanged<ItemCondition> onSelected;

  @override
  Widget build(BuildContext context) => ItemTagGroupField(
    label: context.l10n.itemCondition,
    children: <Widget>[
      for (final ItemCondition condition in ItemCondition.values)
        SdTagV3(
          label: condition.label(context),
          color: condition.color(context),
          selected: selected == condition,
          onSelected: () => onSelected(condition),
        ),
    ],
  );
}

class ItemCategoryField extends ConsumerWidget {
  const ItemCategoryField({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ItemCategory> categories =
        ref.watch(categoriesProvider).value ?? const <ItemCategory>[];
    final Map<String, String> names = ref.watch(categoryNamesProvider);

    return PickerField(
      label: context.l10n.commonCategory,
      icon: AppIconConstant.category,
      value: selected == null ? null : names[selected],
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
                selected: selected,
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

              onSelected(picked);
            },
    );
  }
}

class ItemLocationField extends ConsumerWidget {
  const ItemLocationField({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<StorageLocation> locations =
        ref.watch(locationsProvider).value ?? const <StorageLocation>[];
    final Map<String, String> paths = ref.watch(locationPathsProvider);

    return PickerField(
      label: context.l10n.commonLocation,
      icon: AppIconConstant.shelves,
      value: selected == null ? null : paths[selected],
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
                selected: selected,
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

              onSelected(picked);
            },
    );
  }
}

class ItemSourceField extends ConsumerWidget {
  const ItemSourceField({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Source> sources =
        ref.watch(sourcesProvider).value ?? const <Source>[];
    final Map<String, String> names = ref.watch(sourceNamesProvider);

    return PickerField(
      label: context.l10n.commonSource,
      icon: AppIconConstant.storefront,
      value: selected == null ? null : names[selected],
      placeholder: sources.isEmpty ? context.l10n.itemSourceEmptyHint : null,
      onTap: sources.isEmpty
          ? () =>
                SdSnackBarUtilsV3.info(context, context.l10n.itemAddSourceFirst)
          : () async {
              final String? picked = await OptionPickerSheet.show<String>(
                context,
                title: context.l10n.commonSource,
                selected: selected,
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

              onSelected(picked);
            },
    );
  }
}

class ItemPurchaseDateField extends StatelessWidget {
  const ItemPurchaseDateField({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return PickerField(
      label: context.l10n.itemPurchaseDate,
      icon: AppIconConstant.calendarMonth,
      value: selected == null
          ? null
          : DateTimeUtils.mediumDate(selected!, locale: context.localeTag),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selected ?? now,
          firstDate: DateTime(now.year - DatePickerConstant.taxRecordYearsBack),
          // No future purchase dates: a receipt cannot be from next month, and
          // one filed there breaks every period report it lands in.
          lastDate: now,
        );

        if (picked == null) return;

        onSelected(picked);
      },
    );
  }
}
