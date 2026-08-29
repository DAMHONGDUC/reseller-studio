import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';
import 'app_selectable_row.dart';
import 'app_sheet_option_list.dart';

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

  /// Whether a search query matches this row. The caption counts, so typing a
  /// country's code finds it as well as its name.
  bool matches(String query) =>
      label.toLowerCase().contains(query) ||
      (caption?.toLowerCase().contains(query) ?? false);
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
///
/// **[searchHint] turns on the search box**, and a list long enough to need
/// scrolling should pass one: the country picker holds every country, and a
/// list that long with no way to filter it is a list nobody reaches the end
/// of. A short list is faster to read than to type at, so it goes without.
class OptionPickerSheet<T> extends StatefulWidget {
  const OptionPickerSheet({
    required this.title,
    required this.options,
    this.selected,
    this.searchHint,
    super.key,
  });

  final String title;
  final List<PickerOption<T>> options;
  final T? selected;
  final String? searchHint;

  /// Present the sheet and wait for a choice.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<PickerOption<T>> options,
    T? selected,
    String? searchHint,
  }) => showSdBottomSheetV3<T>(
    context: context,
    builder: (BuildContext context) => OptionPickerSheet<T>(
      title: title,
      options: options,
      selected: selected,
      searchHint: searchHint,
    ),
  );

  /// How tall the list may grow before it scrolls inside the sheet.
  static double get listMaxHeight => SdSpacingConstant.h200 * 2;

  @override
  State<OptionPickerSheet<T>> createState() => _OptionPickerSheetState<T>();
}

class _OptionPickerSheetState<T> extends State<OptionPickerSheet<T>> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _query.text.trim().toLowerCase();

    final List<PickerOption<T>> visible = query.isEmpty
        ? widget.options
        : widget.options
              .where((PickerOption<T> option) => option.matches(query))
              .toList();

    return SdBottomSheetV3(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.searchHint != null) ...<Widget>[
            SdSearchFieldV3(
              controller: _query,
              hint: widget.searchHint!,
              clearTooltip: context.l10n.commonClear,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: SdSpacingConstant.h12),
          ],
          if (visible.isEmpty)
            Padding(
              padding: SdContentPaddingV3.row,
              child: Text(
                context.l10n.commonNoResults,
                style: context.textTheme3.bodyMedium!.muted3(context),
              ),
            )
          else
            AppSheetOptionList(
              maxHeight: OptionPickerSheet.listMaxHeight,
              itemCount: visible.length,
              itemBuilder: (BuildContext context, int index) {
                final PickerOption<T> option = visible[index];

                return _PickerRow<T>(
                  option: option,
                  isSelected: option.value == widget.selected,
                  onTap: () => Navigator.of(context).pop(option.value),
                );
              },
            ),
        ],
      ),
    );
  }
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
          if (isSelected) SdIconV3(AppIconConstant.check, color: accent),
        ],
      ),
    );
  }
}
