import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import 'app_selectable_row.dart';

/// One row in an [OptionPickerSheet].
///
/// [label] is a finished, localized string — the sheet does no formatting and
/// knows nothing about what it is picking.
class PickerOption<T> {
  const PickerOption({
    required this.value,
    required this.label,
    this.caption,
    this.icon,
  });

  final T value;
  final String label;

  /// A second line: what a marketplace's fee rate is, what a category covers.
  final String? caption;

  final IconData? icon;
}

/// The app's one "choose one of these" sheet.
///
/// Currency, country, condition, marketplace, category, source, carrier —
/// every one of them is the same interaction, and a screen that rolled its
/// own would be the second look for the same job. In `core/widgets/` because
/// more than one feature uses it.
///
/// Returns the chosen value, or null if the seller dismissed the sheet
/// without picking. **Null means "left it alone", never "cleared it"** — a
/// caller that treats a dismissal as a change would wipe a field every time
/// somebody tapped outside.
class OptionPickerSheet<T> extends StatelessWidget {
  const OptionPickerSheet({
    required this.title,
    required this.options,
    this.selected,
    super.key,
  });

  final String title;
  final List<PickerOption<T>> options;
  final T? selected;

  /// Present the sheet and wait for a choice.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<PickerOption<T>> options,
    T? selected,
  }) => showSdBottomSheetV3<T>(
    context: context,
    builder: (BuildContext context) => OptionPickerSheet<T>(
      title: title,
      options: options,
      selected: selected,
    ),
  );

  @override
  Widget build(BuildContext context) => SdBottomSheetV3(
    title: title,
    child: ConstrainedBox(
      // Capped so a long list — every currency, say — scrolls inside the
      // sheet instead of growing it past the top of the screen.
      constraints: BoxConstraints(maxHeight: SdSpacingConstant.h200 * 2),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: options.length,
        // A gap rather than a hairline: each row carries its own rounded
        // ground when chosen, and a divider cutting through that reads as two
        // competing shapes.
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(height: SdSpacingConstant.h4),
        itemBuilder: (BuildContext context, int index) {
          final PickerOption<T> option = options[index];

          return _PickerRow<T>(
            option: option,
            isSelected: option.value == selected,
            onTap: () => Navigator.of(context).pop(option.value),
          );
        },
      ),
    ),
  );
}

class _PickerRow<T> extends StatelessWidget {
  const _PickerRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final PickerOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = context.colorScheme3.primary;

    return AppSelectableRow(
      isSelected: isSelected,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          if (option.icon != null) ...<Widget>[
            SdIconV3(
              option.icon!,
              color: isSelected ? accent : context.sdTheme3.textSecondary,
            ),
            SizedBox(width: SdSpacingConstant.w12),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  option.label,
                  // Weight as well as colour: the chosen row has to be
                  // findable by someone who cannot tell the two apart.
                  style: isSelected
                      ? context.textTheme3.bodyMedium!.semiBold3.copyWith(
                          color: accent,
                        )
                      : context.textTheme3.bodyMedium!.copyWith(
                          color: context.sdTheme3.textPrimary,
                        ),
                ),
                if (option.caption != null) ...<Widget>[
                  SizedBox(height: SdSpacingConstant.h2),
                  Text(
                    option.caption!,
                    style: context.textTheme3.bodySmall!.faint3(context),
                  ),
                ],
              ],
            ),
          ),
          // A tick as well as the ground and the weight: colour is never the
          // only signal for a state.
          if (isSelected) SdIconV3(Symbols.check_rounded, color: accent),
        ],
      ),
    );
  }
}
