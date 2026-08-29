import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/tax/domain/entities/mileage_journey.dart';
import 'package:reseller_studio/features/tax/domain/entities/mileage_rate.dart';
import 'package:reseller_studio/features/tax/domain/enums/tax_jurisdiction.dart';
import 'package:reseller_studio/features/tax/domain/services/mileage_calculator.dart';

/// The UK rate is banded and the US rate is not; the banding is over the
/// year's total rather than per journey, while the *rate* is per journey.
/// Those two pull in opposite directions and that is the expensive part to
/// get wrong.
void main() {
  group('a single unbounded band (US)', () {
    final MileageRate? rate = MileageCalculator.rateFor(
      TaxJurisdiction.us,
      DateTime(2025, DateTime.june),
    );

    test('the published rate is found by date', () {
      expect(rate, isNotNull);
      expect(rate!.bands.single.rateMinorHundredths, 7000);
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

  group('two bands, the rates in force before April 2026 (UK)', () {
    final MileageRate? rate = MileageCalculator.rateFor(
      TaxJurisdiction.uk,
      DateTime(2025, DateTime.june),
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

  group('the UK first band rose to 55p on 6 April 2026', () {
    test('the day it takes effect already uses the new rate', () {
      expect(
        MileageCalculator.rateFor(
          TaxJurisdiction.uk,
          DateTime(2026, DateTime.april, 6),
        )!.bands.first.rateMinorHundredths,
        5500,
      );
    });

    test('the day before it still uses the old one', () {
      expect(
        MileageCalculator.rateFor(
          TaxJurisdiction.uk,
          DateTime(2026, DateTime.april, 5),
        )!.bands.first.rateMinorHundredths,
        4500,
      );
    });

    test('the second band did not move', () {
      expect(
        MileageCalculator.rateFor(
          TaxJurisdiction.uk,
          DateTime(2026, DateTime.june),
        )!.bands.last.rateMinorHundredths,
        2500,
      );
    });

    test('over the threshold splits at the new first-band rate', () {
      // 10,000 × 55p + 2,000 × 25p
      expect(
        MileageCalculator.forJourneys(
          journeys: <MileageJourney>[
            MileageJourney(
              date: DateTime(2026, DateTime.june),
              distance: 12000,
            ),
          ],
          jurisdiction: TaxJurisdiction.uk,
          currency: 'GBP',
        ),
        const Money(600000, 'GBP'),
      );
    });
  });

  group('a rate that changes mid-year (US 2026)', () {
    test('each journey is rated by its own date', () {
      // 500 × 72.5¢ before 1 July, 500 × 76¢ after. A single figure for the
      // year would give one of these twice and understate or overstate it.
      expect(
        MileageCalculator.forJourneys(
          journeys: <MileageJourney>[
            MileageJourney(
              date: DateTime(2026, DateTime.february),
              distance: 500,
            ),
            MileageJourney(
              date: DateTime(2026, DateTime.august),
              distance: 500,
            ),
          ],
          jurisdiction: TaxJurisdiction.us,
          currency: 'USD',
        ),
        const Money(74250, 'USD'),
      );
    });

    test('1 July is the new rate, 30 June is the old one', () {
      expect(
        MileageCalculator.rateFor(
          TaxJurisdiction.us,
          DateTime(2026, DateTime.july),
        )!.bands.single.rateMinorHundredths,
        7600,
      );
      expect(
        MileageCalculator.rateFor(
          TaxJurisdiction.us,
          DateTime(2026, DateTime.june, 30),
        )!.bands.single.rateMinorHundredths,
        7250,
      );
    });

    test('a half-cent rate rounds once, at the end', () {
      // 3 × 72.5¢ is 217.5¢. Rounded per journey it would be 3 × 73 = 219.
      expect(
        MileageCalculator.forJourneys(
          journeys: <MileageJourney>[
            for (int i = 0; i < 3; i++)
              MileageJourney(
                date: DateTime(2026, DateTime.february),
                distance: 1,
              ),
          ],
          jurisdiction: TaxJurisdiction.us,
          currency: 'USD',
        ),
        const Money(218, 'USD'),
      );
    });
  });

  group('bands are cumulative across journeys, not restarted by each', () {
    test('two trips either side of the threshold split once', () {
      // 8,000 then 4,000: the first 10,000 at 55p, the last 2,000 at 25p.
      expect(
        MileageCalculator.forJourneys(
          journeys: <MileageJourney>[
            MileageJourney(date: DateTime(2026, DateTime.may), distance: 8000),
            MileageJourney(date: DateTime(2026, DateTime.june), distance: 4000),
          ],
          jurisdiction: TaxJurisdiction.uk,
          currency: 'GBP',
        ),
        const Money(600000, 'GBP'),
      );
    });

    test('order of the list does not matter, the dates decide', () {
      expect(
        MileageCalculator.forJourneys(
          journeys: <MileageJourney>[
            MileageJourney(date: DateTime(2026, DateTime.june), distance: 4000),
            MileageJourney(date: DateTime(2026, DateTime.may), distance: 8000),
          ],
          jurisdiction: TaxJurisdiction.uk,
          currency: 'GBP',
        ),
        const Money(600000, 'GBP'),
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
        MileageCalculator.deduction(distance: 500, rate: null, currency: 'USD'),
        isNull,
      );
    });

    test('one unrated journey makes the whole year unknown', () {
      expect(
        MileageCalculator.forJourneys(
          journeys: <MileageJourney>[
            MileageJourney(date: DateTime(2025, DateTime.june), distance: 100),
            MileageJourney(date: DateTime(1999), distance: 100),
          ],
          jurisdiction: TaxJurisdiction.us,
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
      )!.bands.single.rateMinorHundredths,
      6700,
    );
  });
}
