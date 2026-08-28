import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_card.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';
import 'package:reseller_studio/features/marketplaces/domain/enums/marketplace.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

void main() {
  final Item item = Item(
    id: 'itm-1',
    title: 'Vintage jacket',
    quantity: 1,
    status: ItemStatus.listed,
    createdAt: testNow,
    listedAt: testNow,
    askingPrice: const Money(4500, 'USD'),
  );

  Listing listingOn(Marketplace marketplace, int minorUnits) => Listing(
    id: 'lst-${marketplace.name}',
    itemId: item.id,
    marketplace: marketplace,
    title: item.title,
    price: Money(minorUnits, 'USD'),
    status: ListingStatus.active,
    createdAt: testNow,
  );

  testWidgets('the card names every marketplace and prices none of them', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: item,
        now: testNow,
        listings: <Listing>[
          listingOn(Marketplace.ebay, 4500),
          listingOn(Marketplace.depop, 4000),
          listingOn(Marketplace.poshmark, 5000),
        ],
      ),
    );

    expect(find.widgetWithText(SdBadgeV3, 'eBay'), findsOneWidget);
    expect(find.widgetWithText(SdBadgeV3, 'Depop'), findsOneWidget);
    expect(find.widgetWithText(SdBadgeV3, 'Poshmark'), findsOneWidget);
    // The asking price is the item's own number and stays; a listing's is not
    // on the row any more.
    expect(find.text(r'$45.00'), findsOneWidget);
    expect(find.text(r'$40.00'), findsNothing);
    expect(find.text(r'$50.00'), findsNothing);
  });

  testWidgets('an item on no marketplace names none', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, ItemCard(item: item, now: testNow));

    for (final Marketplace marketplace in Marketplace.values) {
      expect(
        find.widgetWithText(SdBadgeV3, marketplace.displayName),
        findsNothing,
      );
    }
  });
}
