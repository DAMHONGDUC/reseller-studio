import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/presentation/controllers/listing_actions_controller.dart';
import 'package:reseller_studio/features/listings/providers.dart';

import '../../support/pump_app.dart';

/// Item detail tells the story of its prices once there is one, and draws
/// nothing — not even a heading — before.
void main() {
  testWidgets('a reprice appears under Price history with its reason', (
    WidgetTester tester,
  ) async {
    const String itemId = 'itm-4';
    final Finder heading = find.text('Price history');

    await pumpScreen(tester, const ItemDetailScreen(itemId: itemId));

    expect(heading, findsNothing);

    // Every section is open, so Listings is below the screen; building it is
    // what starts the stream the read below waits on.
    await tester.scrollUntilVisible(
      find.text('Listings'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(ItemDetailScreen)),
    );
    final List<Listing> listings = await container.read(
      listingsForItemProvider(itemId).future,
    );
    final Listing listing = listings.first;

    await container.read(listingActionsControllerProvider.notifier).reprice(
      <Listing>[listing],
      Money(listing.price.minor + 500, listing.price.currency),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      heading,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(heading, findsOneWidget);
    expect(find.textContaining('Bulk reprice'), findsOneWidget);
  });
}
