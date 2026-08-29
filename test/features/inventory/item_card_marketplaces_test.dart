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
    status: ItemStatus.inStock,
    createdAt: testNow,
    listedAt: testNow,
    askingPrice: const Money(4500, 'USD'),
  );

  Listing listingOn(
    Marketplace marketplace,
    int minorUnits, {
    String suffix = '',
  }) => Listing(
    id: 'lst-${marketplace.name}$suffix',
    itemId: item.id,
    marketplace: marketplace,
    title: item.title,
    price: Money(minorUnits, 'USD'),
    status: ListingStatus.active,
    createdAt: testNow,
  );

  testWidgets('the card counts distinct marketplaces and prices none of them', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: item,
        now: testNow,
        listings: <Listing>[
          listingOn(Marketplace.ebay, 4500),
          listingOn(Marketplace.ebay, 4200, suffix: '-duplicate'),
          listingOn(Marketplace.depop, 4000),
          listingOn(Marketplace.poshmark, 5000),
        ],
      ),
    );

    expect(find.widgetWithText(SdBadgeV3, '3 markets'), findsOneWidget);
    final double ageY = tester
        .getTopLeft(find.widgetWithText(SdBadgeV3, '<1d'))
        .dy;
    final double marketY = tester
        .getTopLeft(find.widgetWithText(SdBadgeV3, '3 markets'))
        .dy;
    expect(ageY, lessThan(marketY));
    expect(find.text('eBay'), findsNothing);
    expect(find.text('Depop'), findsNothing);
    expect(find.text('Poshmark'), findsNothing);
    // The item's own asking price stays; a listing's is not on the row any
    // more.
    expect(find.text(r'$45.00'), findsOneWidget);
    expect(find.text(r'$40.00'), findsNothing);
    expect(find.text(r'$50.00'), findsNothing);
  });

  testWidgets('an item on no marketplace shows no marketplace count', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, ItemCard(item: item, now: testNow));

    expect(find.textContaining('market'), findsNothing);
  });
}
