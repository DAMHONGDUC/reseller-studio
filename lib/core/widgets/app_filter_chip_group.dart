import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

/// One choice inside an [AppFilterChipGroup].
///
/// [label] is a finished, localized string — the group does no formatting and
/// knows nothing about what it is filtering, the same contract
/// `PickerOption` has.
class AppFilterOption<T> {
  const AppFilterOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// A titled block of filter chips inside a filter sheet.
///
/// **The chips wrap, they do not scroll sideways.** `AppFilterStrip` is the
/// horizontal one and belongs above a list, where a seller is choosing one
/// tab; a sheet is read top to bottom, and a category hidden off the right
/// edge of a group is a category nobody finds.
///
/// The group holds no selection logic on purpose: [selected] is whatever the
/// caller's criteria say, and [onSelected] decides whether a tap toggles one
/// of many or replaces one of three. A widget that assumed one of those would
/// be wrong for half the groups in either sheet.
class AppFilterChipGroup<T> extends StatelessWidget {
  const AppFilterChipGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String title;
  final List<AppFilterOption<T>> options;

  /// The values currently chosen — one for a single-choice group, any number
  /// for a multi-select one.
  final Set<T> selected;

  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        title,
        style: context.textTheme3.labelMedium!.semiBold3.copyWith(
          color: context.sdTheme3.textSecondary,
        ),
      ),
      SizedBox(height: SdSpacingConstant.h8),
      Wrap(
        spacing: SdSpacingConstant.w8,
        runSpacing: SdSpacingConstant.h8,
        children: <Widget>[
          for (final AppFilterOption<T> option in options)
            SdFilterChipV3(
              label: option.label,
              selected: selected.contains(option.value),
              onSelected: () => onSelected(option.value),
            ),
        ],
      ),
    ],
  );
}
