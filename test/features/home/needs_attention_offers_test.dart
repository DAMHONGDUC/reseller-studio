import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/utils/date_time_utils.dart';
import 'package:reseller_studio/features/offers/domain/entities/offer.dart';
import 'package:reseller_studio/features/offers/providers.dart';

import '../../support/pump_app.dart';

/// Plan §6 names four rows in Needs Attention and Home built three: offers
/// were the missing one, even though `pendingOffersProvider` said in its own
/// doc that this is what it was for.
void main() {
  test('the seeded business has offers waiting on a decision', () async {
    final ProviderContainer container = mockContainer();

    await warmUp(container);

    final List<Offer> pending = container.read(pendingOffersProvider);

    expect(pending, isNotEmpty);
    // Sorted soonest-to-lapse first, which is what the row's detail reads.
    expect(pending.first.needsAction, isTrue);
  });

  group('how long is left', () {
    test('hours matter, because an offer can lapse this afternoon', () {
      expect(DateTimeUtils.compactRemaining(const Duration(hours: 4)), '4h');
      expect(
        DateTimeUtils.compactRemaining(const Duration(minutes: 20)),
        '<1h',
      );
    });

    test('past two days it reads in days', () {
      expect(DateTimeUtils.compactRemaining(const Duration(days: 3)), '3d');
    });

    test('a deadline already gone is now, never a negative', () {
      expect(DateTimeUtils.compactRemaining(const Duration(hours: -5)), 'now');
    });
  });
}
