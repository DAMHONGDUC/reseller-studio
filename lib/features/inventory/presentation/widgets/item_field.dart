import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/constants/date_picker_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/text_input_utils.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../../core/widgets/picker_field.dart';
import '../../../sourcing/domain/entities/purchase.dart';
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

/// How many there are — a box to type in, and a step either side of it.
///
/// **The stepper is the point** — owner's rule. One more or one fewer is what
/// actually happens to a count, and doing that by selecting a number and
/// typing another is three interactions for an increment. The box stays for
/// the times the answer is twelve.
///
/// **`-1` stops at zero.** A negative count is a number nothing in the app can
/// mean, so the button is disabled rather than writing one.
class ItemQuantityField extends StatelessWidget {
  const ItemQuantityField({
    required this.controller,
    this.textInputAction,
    super.key,
  });

  final TextEditingController controller;
  final TextInputAction? textInputAction;

  void _step(int by) {
    final int next = TextInputUtils.stepCount(controller.text, by);

    // Through the controller, so the box and the buttons cannot disagree
    // about what the count is.
    controller.text = '$next';
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (BuildContext context, TextEditingValue value, Widget? _) =>
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SdButtonV3(
                  variant: SdButtonVariantV3.outlined,
                  label: context.l10n.itemQuantityDecrement,
                  onPressed: TextInputUtils.stepCount(value.text, 0) == 0
                      ? null
                      : () => _step(-1),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(
                  child: SdTextFieldV3(
                    label: context.l10n.commonQuantity,
                    controller: controller,
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    textInputAction: textInputAction,
                  ),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                SdButtonV3(
                  variant: SdButtonVariantV3.outlined,
                  label: context.l10n.itemQuantityIncrement,
                  onPressed: () => _step(1),
                ),
              ],
            ),
      );
}

/// Where the item is in its life — four tags, each wearing its own colour.
///
/// **Switching is free** — owner's rule. No requirement is checked and no move
/// is refused: this is where a seller corrects what the app got wrong, and a
/// correction that argues back is the thing they came to fix. The *verbs* are
/// unchanged — `ItemTransition.check` still gates Mark as sold and the bulk
/// paths, which is where a missing price actually matters.
///
/// **It writes no order** (hard rule 3) and **moves no count** (quantity and
/// status are independent, `lib/features/inventory/CLAUDE.md`): a pair that
/// cannot both be true is drawn as an alert tag instead.
class ItemStatusField extends StatelessWidget {
  const ItemStatusField({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ItemStatus selected;
  final ValueChanged<ItemStatus> onSelected;

  @override
  Widget build(BuildContext context) => ItemTagGroupField(
    label: context.l10n.itemStatus,
    children: <Widget>[
      for (final ItemStatus status in ItemStatus.values)
        SdTagV3(
          label: status.label(context),
          color: status.color(context),
          selected: selected == status,
          onSelected: () => onSelected(status),
        ),
    ],
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

/// Which buying trip this item came off.
///
/// **The link Sourcing is built on, and the form had no box for it.** An item
/// with no `purchaseId` cannot be apportioned a receipt, so the lot sat alone
/// in Books and every source ranked with no return — while the purchase
/// screen's own empty state told the seller to set it "on the item form".
///
/// Picking a trip fills the source and the date with it: they are facts about
/// the trip, so making the seller retype them is three chances to disagree
/// with the record they just pointed at.
class ItemPurchaseField extends ConsumerWidget {
  const ItemPurchaseField({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Purchase> purchases =
        ref.watch(purchasesProvider).value ?? const <Purchase>[];
    final Map<String, String> sources = ref.watch(sourceNamesProvider);

    String label(Purchase purchase) => DateTimeUtils.mediumDate(
      purchase.purchaseDate,
      locale: context.localeTag,
    );

    String? caption(Purchase purchase) {
      final String? source = sources[purchase.sourceId];
      final Money? total = purchase.totalCost;

      if (source == null && total == null) return null;

      return <String>[
        ?source,
        ?total?.format(locale: context.localeTag),
      ].join(' · ');
    }

    final Purchase? current = purchases
        .where((Purchase purchase) => purchase.id == selected)
        .firstOrNull;

    return PickerField(
      label: context.l10n.itemPurchase,
      icon: AppIconConstant.receipt,
      value: current == null ? null : label(current),
      placeholder: purchases.isEmpty ? context.l10n.itemPurchaseEmptyHint : null,
      onTap: purchases.isEmpty
          ? () => SdSnackBarUtilsV3.info(
              context,
              context.l10n.itemAddPurchaseFirst,
            )
          : () async {
              final String? picked = await OptionPickerSheet.show<String>(
                context,
                title: context.l10n.itemPurchase,
                selected: selected,
                options: purchases
                    .map(
                      (Purchase purchase) => PickerOption<String>(
                        value: purchase.id,
                        label: label(purchase),
                        caption: caption(purchase),
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
