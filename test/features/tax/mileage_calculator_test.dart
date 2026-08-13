import 'package:flutter_test/flutter_test.dart';
import 'package:seller_os/core/money/money.dart';
import 'package:seller_os/features/tax/domain/entities/mileage_rate.dart';
import 'package:seller_os/features/tax/domain/enums/tax_jurisdiction.dart';
import 'package:seller_os/features/tax/domain/services/mileage_calculator.dart';

/// The UK rate is banded and the US rate is not, and the banding is over the
/// year's total rather than per journey — which is the part that is easy to
/// get wrong and expensive to get wrong.
void main() {
  group('a single unbounded band (US)', () {
    final MileageRate? rate = MileageCalculator.rateFor(
      TaxJurisdiction.us,
      DateTime(2025, DateTime.june),
    );

    test('the published rate is found by date', () {
      expect(rate, isNotNull);
      expect(rate!.bands.single.rateMinor, 70);
    });

    test('distance times rate, in minor units', () {
      expect(
        MileageCalculator.deduction(
          distance: 1000,
          rate: rate,
          currency: 'USD',
        ),
        const Money(70000, 'USD'),
      );
    });
  });

  group('two bands (UK)', () {
    final MileageRate? rate = MileageCalculator.rateFor(
      TaxJurisdiction.uk,
      DateTime(2026, DateTime.april, 6),
    );

    test('under the threshold, everything is at the first band', () {
      // 5,000 × 45p
      expect(
        MileageCalculator.deduction(
          distance: 5000,
          rate: rate,
          currency: 'GBP',
        ),
        const Money(225000, 'GBP'),
      );
    });

    test('exactly at the threshold is still all first band', () {
      expect(
        MileageCalculator.deduction(
          distance: 10000,
          rate: rate,
          currency: 'GBP',
        ),
        const Money(450000, 'GBP'),
      );
    });

    test('over the threshold splits, it does not re-rate the whole year', () {
      // 10,000 × 45p + 2,000 × 25p — not 12,000 × 25p, and not 12,000 × 45p.
      expect(
        MileageCalculator.deduction(
          distance: 12000,
          rate: rate,
          currency: 'GBP',
        ),
        const Money(500000, 'GBP'),
      );
    });
  });

  group('the answers that are not numbers', () {
    test('no published rate is null, never a zero deduction', () {
      // Hard rule 5's reasoning: telling a seller their mileage is worth
      // nothing is worse than telling them it is unknown.
      expect(
        MileageCalculator.rateFor(TaxJurisdiction.us, DateTime(1999)),
        isNull,
      );
      expect(
        MileageCalculator.deduction(
          distance: 500,
          rate: null,
          currency: 'USD',
        ),
        isNull,
      );
    });

    test('no distance is a real zero', () {
      expect(
        MileageCalculator.deduction(
          distance: 0,
          rate: MileageCalculator.rateFor(TaxJurisdiction.us, DateTime(2025)),
          currency: 'USD',
        ),
        const Money(0, 'USD'),
      );
    });
  });

  test('a journey is rated by its own date, not by the newest table', () {
    // A 2024 journey deducts at the 2024 rate even though a 2025 one exists.
    expect(
      MileageCalculator.rateFor(
        TaxJurisdiction.us,
        DateTime(2024, DateTime.july),
      )!.bands.single.rateMinor,
      67,
    );
  });
}
