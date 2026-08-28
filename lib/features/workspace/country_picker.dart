import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/option_picker_sheet.dart';
import 'country_constant.dart';
import 'country_label.dart';

/// Ask the seller which country their business is in.
///
/// One presenter rather than a list built at each call site: setup and
/// settings both ask, and the searchable sheet, the code caption and the
/// ordering are all decisions that would drift the moment there were two of
/// them.
///
/// Returns the chosen alpha-2 code, or null if the sheet was dismissed —
/// which means "left it alone", never "cleared it".
final class CountryPicker {
  static Future<String?> show(BuildContext context, {String? selected}) =>
      OptionPickerSheet.show<String>(
        context,
        title: context.l10n.workspaceCountry,
        // Every country is in here, so the search box is not optional.
        searchHint: context.l10n.workspaceCountrySearchHint,
        selected: selected,
        options: CountryConstant.codes
            .map(
              (String code) => PickerOption<String>(
                value: code,
                label: CountryLabel.of(context, code),
                // Also what the search matches on, so somebody who thinks in
                // codes can type GB.
                caption: code,
              ),
            )
            .toList(),
      );
}
