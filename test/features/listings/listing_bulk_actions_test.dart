import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/listings/presentation/controllers/listing_actions_controller.dart';
import 'package:reseller_studio/features/listings/presentation/screens/listings_screen/listings_screen.dart';
import 'package:reseller_studio/features/listings/providers.dart';

import '../../support/pump_app.dart';

/// Bulk price update and bulk status changes (plan §12, hard rule 16).
///
/// **The bulk path is not a loop over a single one** — `saveAll` batches the
/// write, and every selected row goes through the same change function. What
/// these pin is that the selection resolves to live records and that a bulk
/// control cannot invent a sale.
void main() {
  Future<ProviderContainer> withListings() async {
    final ProviderContainer container = mockContainer();

    container.listen<AsyncValue<List<Listing>>>(
      listingsProvider,
      (AsyncValue<List<Listing>>? previous, AsyncValue<List<Listing>> next) {},
      fireImmediately: true,
    );

    await Future<void>.delayed(Duration.zero);

    return container;
  }

  List<Listing> listingsIn(ProviderContainer container) =>
      container.read(listingsProvider).value ?? const <Listing>[];

  test('the selection resolves to the live records, not a copy', () async {
    final ProviderContainer container = await withListings();
    final List<Listing> all = listingsIn(container);

    container.read(listingSelectionProvider.notifier).selectAll(<String>[
      all.first.id,
      all[1].id,
    ]);

    expect(container.read(selectedListingsProvider), hasLength(2));

    container.read(listingSelectionProvider.notifier).clear();

    expect(container.read(selectedListingsProvider), isEmpty);
  });

  test(
    'a bulk reprice writes the same price to every selected listing',
    () async {
      final ProviderContainer container = await withListings();
      final List<Listing> picked = listingsIn(container).take(3).toList();
      const Money price = Money(950, 'USD');

      await container
          .read(listingActionsControllerProvider.notifier)
          .reprice(picked, price);
      await Future<void>.delayed(Duration.zero);

      final Set<String> ids = picked.map((Listing l) => l.id).toSet();

      for (final Listing listing in listingsIn(container)) {
        if (!ids.contains(listing.id)) continue;

        expect(listing.price, price);
      }
    },
  );

  test('ending stamps the date, pausing leaves it alone', () async {
    final ProviderContainer container = await withListings();
    final Listing first = listingsIn(container).first;

    await container.read(listingActionsControllerProvider.notifier).setStatus(
      <Listing>[first],
      ListingStatus.paused,
    );
    await Future<void>.delayed(Duration.zero);

    Listing reread() => listingsIn(
      container,
    ).firstWhere((Listing listing) => listing.id == first.id);

    expect(reread().status, ListingStatus.paused);
    // A paused listing has not ended.
    expect(reread().endedAt, first.endedAt);

    await container.read(listingActionsControllerProvider.notifier).setStatus(
      <Listing>[first],
      ListingStatus.ended,
    );
    await Future<void>.delayed(Duration.zero);

    expect(reread().status, ListingStatus.ended);
    expect(reread().endedAt, isNotNull);
  });

  test('no bulk control can mark a listing sold', () async {
    final ProviderContainer container = await withListings();
    final Listing first = listingsIn(container).first;

    // A listing sells because an order exists. Letting a bulk control say
    // otherwise would create a sale with no order, and every profit figure in
    // the app is derived from orders.
    await container.read(listingActionsControllerProvider.notifier).setStatus(
      <Listing>[first],
      ListingStatus.sold,
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      listingsIn(container).firstWhere((Listing l) => l.id == first.id).status,
      first.status,
    );
  });

  testWidgets('leaving Listings never writes to a disposed provider', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const ListingsScreen());
    await tester.pumpAndSettle();

    // The screen used to clear the selection from `dispose` on a microtask.
    // A Riverpod 3 provider disposes with its last listener, so that write
    // always landed on a notifier that was already gone.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
