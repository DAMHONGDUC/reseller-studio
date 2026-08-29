/// Formats the normalized, editable representation of a money amount.
final class CurrencyInputUtils {
  const CurrencyInputUtils._();

  /// Adds comma grouping and limits the decimal portion.
  static String format(String input, {required int decimalPlaces}) {
    final String normalized = normalize(input);
    if (normalized.isEmpty) return '';

    final int dot = normalized.indexOf('.');
    final String integer = dot == -1
        ? normalized
        : normalized.substring(0, dot);
    final String decimal = dot == -1 ? '' : normalized.substring(dot + 1);
    final String digits = integer.isEmpty ? '0' : integer;
    final StringBuffer grouped = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) grouped.write(',');
      grouped.write(digits[index]);
    }

    if (dot != -1 && decimalPlaces > 0) {
      grouped
        ..write('.')
        ..write(decimal.substring(0, decimal.length.clamp(0, decimalPlaces)));
    }

    return grouped.toString();
  }

  /// Removes grouping and unsupported characters, retaining one decimal dot.
  static String normalize(String input) {
    final StringBuffer output = StringBuffer();
    bool hasDecimal = false;

    for (final int rune in input.runes) {
      final String character = String.fromCharCode(rune);
      if (character == ',') continue;
      if (character == '.' && !hasDecimal) {
        output.write(character);
        hasDecimal = true;
      } else if (RegExp(r'[0-9]').hasMatch(character)) {
        output.write(character);
      }
    }

    return output.toString();
  }
}
