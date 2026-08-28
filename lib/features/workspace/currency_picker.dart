import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/option_picker_sheet.dart';
import 'currency_constant.dart';
import 'currency_label.dart';

/// Ask the seller which currency their business keeps its books in.
///
/// The twin of `CountryPicker`, and one presenter for the same reason: setup
/// and the detail screen both ask, and the searchable sheet, the code caption
/// and the ordering are all decisions that would drift the moment there were
/// two of them.
///
/// Returns the chosen ISO 4217 code, or null if the sheet was dismissed —
/// which means "left it alone", never "cleared it".
final class CurrencyPicker {
  static Future<String?> show(BuildContext context, {String? selected}) =>
      OptionPickerSheet.show<String>(
        context,
        title: context.l10n.workspaceCurrency,
        // Every active currency is in here, so the search box is not optional.
        searchHint: context.l10n.workspaceCurrencySearchHint,
        selected: selected,
        options: CurrencyConstant.codes
            .map(
              (String code) => PickerOption<String>(
                value: code,
                label: CurrencyLabel.of(context, code),
                // Also what the search matches on, so somebody who thinks in
                // codes can type GBP.
                caption: code,
              ),
            )
            .toList(),
      );
}
