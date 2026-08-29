import 'package:flutter/material.dart';
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
    createdAt: testNow.subtract(const Duration(days: 100)),
    listedAt: testNow.subtract(const Duration(days: 100)),
    askingPrice: const Money(4500, 'USD'),
    condition: ItemCondition.good,
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

    final Finder statusTag = find.widgetWithText(SdBadgeV3, 'In stock');
    final Finder marketTag = find.widgetWithText(SdBadgeV3, '3 markets');
    final Finder allTags = find.byType(SdBadgeV3);

    expect(marketTag, findsOneWidget);
    expect(allTags, findsNWidgets(4));
    expect(
      List<double>.generate(
        4,
        (int index) => tester.getSize(allTags.at(index)).height,
      ).toSet(),
      hasLength(1),
    );
    expect(tester.getSize(statusTag).height, tester.getSize(marketTag).height);
    expect(
      find.descendant(
        of: allTags,
        matching: find.byIcon(Icons.radio_button_checked_rounded),
      ),
      findsNothing,
    );
    expect(
      tester.widget<SdBadgeV3>(marketTag).color,
      tester.element(marketTag).sdTheme3.textSecondary,
    );
    // The card reports; it never offers the form's picker.
    expect(find.byType(SdTagV3), findsNothing);
    expect(
      tester.widget<SdBadgeV3>(marketTag).size,
      SdBadgeSizeV3.compact,
    );
    expect(find.text('<1d'), findsNothing);
    expect(find.text('eBay'), findsNothing);
    expect(find.text('Depop'), findsNothing);
    expect(find.text('Poshmark'), findsNothing);
    // The item's own asking price stays; a listing's is not on the row any
    // more.
    expect(find.text(r'$45.00'), findsOneWidget);
    expect(find.text(r'$40.00'), findsNothing);
    expect(find.text(r'$50.00'), findsNothing);
  });

  testWidgets('the marketplace tag is a line of its own, under the state', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      ItemCard(
        item: item,
        now: testNow,
        listings: <Listing>[listingOn(Marketplace.ebay, 4500)],
      ),
    );

    final Rect status = tester.getRect(
      find.widgetWithText(SdBadgeV3, 'In stock'),
    );
    final Rect grade = tester.getRect(find.widgetWithText(SdBadgeV3, 'Good'));
    final Rect market = tester.getRect(
      find.widgetWithText(SdBadgeV3, '1 market'),
    );

    // Line one is what the item is; line two is where it is listed.
    expect(grade.top, moreOrLessEquals(status.top));
    expect(market.top, greaterThan(status.bottom));
    expect(market.left, moreOrLessEquals(status.left));
  });

  testWidgets('an item nobody has listed says so, in red', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, ItemCard(item: item, now: testNow));

    final Finder unlisted = find.widgetWithText(SdBadgeV3, 'Not listed');

    expect(unlisted, findsOneWidget);
    expect(find.textContaining('market'), findsNothing);
    expect(
      tester.widget<SdBadgeV3>(unlisted).color,
      tester.element(unlisted).sdTheme3.danger,
    );
  });

  testWidgets('an item that has left inventory is not called unlisted', (
    WidgetTester tester,
  ) async {
    // Sold and archived are finished, not late: a red tag asking for a
    // listing would be pointing at work nobody has to do.
    await pumpScreen(
      tester,
      ItemCard(item: item.copyWith(status: ItemStatus.sold), now: testNow),
    );

    expect(find.text('Not listed'), findsNothing);
    expect(find.textContaining('market'), findsNothing);
  });
}
