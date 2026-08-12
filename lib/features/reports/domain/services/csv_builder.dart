/// Building a CSV a spreadsheet will actually open.
///
/// Pure Dart, no Flutter, unit-testable — the escaping is the whole of the
/// value here and it is exactly the part that is easy to get subtly wrong.
///
/// **Every field is quoted, always.** Selective quoting means deciding per
/// value whether it contains a comma, a quote or a newline, and the one that
/// slips through shifts every column after it — in a file the seller opens in
/// front of their accountant.
final class CsvBuilder {
  /// RFC 4180's line ending. `\n` alone is fine on a Mac and produces one
  /// long row in older Excel on Windows.
  static const String lineEnding = '\r\n';

  static String build({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..write(_row(headers))
      ..write(lineEnding);

    for (final List<String> row in rows) {
      buffer
        ..write(_row(row))
        ..write(lineEnding);
    }

    return buffer.toString();
  }

  static String _row(List<String> fields) => fields.map(_escape).join(',');

  /// A quoted field, with any embedded quote doubled — which is how CSV
  /// escapes a quote, and the only escape the format has.
  static String _escape(String value) {
    final String escaped = value.replaceAll('"', '""');

    return '"$escaped"';
  }
}
