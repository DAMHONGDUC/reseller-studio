import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/features/reports/domain/services/csv_builder.dart';

/// The escaping is the whole value of this class, and it is exactly the part
/// that shifts every column after it when it goes wrong — in a file the seller
/// opens in front of their accountant.
void main() {
  group('CsvBuilder', () {
    test('every field is quoted, whether or not it needs to be', () {
      expect(
        CsvBuilder.build(
          headers: <String>['Item', 'Cost'],
          rows: <List<String>>[
            <String>['Jacket', '19.99'],
          ],
        ),
        '"Item","Cost"\r\n"Jacket","19.99"\r\n',
      );
    });

    test('a comma inside a field does not become a new column', () {
      final String csv = CsvBuilder.build(
        headers: <String>['Title'],
        rows: <List<String>>[
          <String>['Nike Air Max 90, size 10'],
        ],
      );

      expect(csv, contains('"Nike Air Max 90, size 10"'));
    });

    test('a quote inside a field is doubled, which is CSV\'s only escape', () {
      final String csv = CsvBuilder.build(
        headers: <String>['Title'],
        rows: <List<String>>[
          <String>['The "good" one'],
        ],
      );

      expect(csv, contains('"The ""good"" one"'));
    });

    test('a newline inside a field stays inside its quotes', () {
      final String csv = CsvBuilder.build(
        headers: <String>['Notes'],
        rows: <List<String>>[
          <String>['line one\nline two'],
        ],
      );

      expect(csv, contains('"line one\nline two"'));
    });

    test('rows end with CRLF, which older Excel needs', () {
      expect(
        CsvBuilder.build(headers: <String>['A'], rows: <List<String>>[]),
        '"A"${CsvBuilder.lineEnding}',
      );
    });

    test('an empty cell stays empty and never becomes a zero', () {
      // Hard rule 5, carried into the export: a blank is a question an
      // accountant asks; a 0 is a number they sum.
      final String csv = CsvBuilder.build(
        headers: <String>['Cost'],
        rows: <List<String>>[
          <String>[''],
        ],
      );

      expect(csv, '"Cost"\r\n""\r\n');
    });
  });
}
