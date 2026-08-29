import 'package:flutter/services.dart';

import 'currency_decimals.dart';
import 'currency_input_utils.dart';

/// Formats a major-unit currency amount while it is being edited.
///
/// Grouping is deliberately a comma and the decimal separator is deliberately
/// a dot: this is editable machine-readable text passed to [Money.tryParse],
/// not the locale-aware display string shown by `context.money`.
final class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter(String currency)
    : decimalPlaces = CurrencyDecimals.of(currency);

  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String formatted = CurrencyInputUtils.format(
      newValue.text,
      decimalPlaces: decimalPlaces,
    );
    final int logicalCursor = _logicalLength(
      newValue.text.substring(
        0,
        newValue.selection.end.clamp(0, newValue.text.length),
      ),
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _cursorForLogicalLength(formatted, logicalCursor),
      ),
    );
  }

  static int _logicalLength(String input) =>
      CurrencyInputUtils.normalize(input).length;

  static int _cursorForLogicalLength(String formatted, int logicalLength) {
    if (logicalLength == 0) return 0;

    int seen = 0;

    for (int index = 0; index < formatted.length; index++) {
      if (formatted[index] != ',') seen++;
      if (seen >= logicalLength) return index + 1;
    }

    return formatted.length;
  }
}
