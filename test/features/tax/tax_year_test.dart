import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/tax/domain/entities/tax_year.dart';
import 'package:reseller_studio/features/tax/domain/enums/tax_jurisdiction.dart';

/// The UK tax year is the reason this class exists: it opens on 6 April, so a
/// quarter of the calendar belongs to the year before the one `date.year`
/// would give.
void main() {
  group('US — the tax year is the calendar year', () {
    test('January and December are the same year', () {
      expect(
        TaxYear.containing(
          DateTime(2026, DateTime.january, 1),
          TaxJurisdiction.us,
        ).startingYear,
        2026,
      );
      expect(
        TaxYear.containing(
          DateTime(2026, DateTime.december, 31),
          TaxJurisdiction.us,
        ).startingYear,
        2026,
      );
    });

    test('it is named by a single year', () {
      expect(
        const TaxYear(
          jurisdiction: TaxJurisdiction.us,
          startingYear: 2026,
        ).label,
        '2026',
      );
    });
  });

  group('UK — the tax year opens on 6 April', () {
    test('5 April still belongs to the year that opened last April', () {
      expect(
        TaxYear.containing(
          DateTime(2026, DateTime.april, 5),
          TaxJurisdiction.uk,
        ).startingYear,
        2025,
      );
    });

    test('6 April opens the new one', () {
      expect(
        TaxYear.containing(
          DateTime(2026, DateTime.april, 6),
          TaxJurisdiction.uk,
        ).startingYear,
        2026,
      );
    });

    test('February belongs to the previous calendar year', () {
      // The case a naive `date.year` gets wrong, and the whole reason
      // `TaxYear.containing` is not written at a call site.
      expect(
        TaxYear.containing(
          DateTime(2027, DateTime.february, 14),
          TaxJurisdiction.uk,
        ).startingYear,
        2026,
      );
    });

    test('it is named across two years', () {
      expect(
        const TaxYear(
          jurisdiction: TaxJurisdiction.uk,
          startingYear: 2026,
        ).label,
        '2026/27',
      );
    });

    test('a year ending in a century rolls its short form', () {
      expect(
        const TaxYear(
          jurisdiction: TaxJurisdiction.uk,
          startingYear: 2099,
        ).label,
        '2099/00',
      );
    });
  });

  group('boundaries', () {
    const TaxYear uk = TaxYear(
      jurisdiction: TaxJurisdiction.uk,
      startingYear: 2026,
    );

    test('the end is exclusive, so nothing falls between two years', () {
      expect(uk.contains(uk.start), isTrue);
      expect(uk.contains(uk.endExclusive), isFalse);

      // The last instant before the boundary is still in — a sale timestamped
      // there is exactly what an inclusive end date drops.
      expect(
        uk.contains(uk.endExclusive.subtract(const Duration(milliseconds: 1))),
        isTrue,
      );
    });

    test('one year ends where the next begins', () {
      expect(
        uk.endExclusive,
        const TaxYear(
          jurisdiction: TaxJurisdiction.uk,
          startingYear: 2027,
        ).start,
      );
    });
  });
}
