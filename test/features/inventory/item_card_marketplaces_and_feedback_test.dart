import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/money/money.dart';
import 'package:reseller_studio/core/widgets/item_card.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/listings/domain/entities/listing.dart';
import 'package:reseller_studio/features/listings/domain/enums/listing_status.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('Inventory card counts marketplaces without names or prices', (
    WidgetTester tester,
  ) async {
    final Item item = Item(
      id: 'item',
      title: 'Cross-listed item',
      quantity: 1,
      status: ItemStatus.inStock,
      createdAt: testNow,
      listedAt: testNow,
    );
    final List<Listing> listings = <Listing>[
      Listing(
        id: 'ebay',
        itemId: item.id,
        marketplaceId: 'ebay',

        marketplaceName: 'eBay',
        title: item.title,
        price: const Money(4512, 'USD'),
        status: ListingStatus.active,
        createdAt: testNow,
      ),
      Listing(
        id: 'etsy',
        itemId: item.id,
        marketplaceId: 'etsy',

        marketplaceName: 'Etsy',
        title: item.title,
        price: const Money(4099, 'USD'),
        status: ListingStatus.active,
        createdAt: testNow,
      ),
    ];

    await pumpScreen(
      tester,
      ItemCard(item: item, now: testNow, listings: listings),
    );

    expect(find.text('2 markets'), findsOneWidget);
    expect(find.text('eBay'), findsNothing);
    expect(find.text('Etsy'), findsNothing);
    expect(find.textContaining('45.12'), findsNothing);
    expect(find.textContaining('40.99'), findsNothing);
  });

  test('successful item actions do not present a toast', () {
    const List<String> paths = <String>[
      'lib/features/inventory/presentation/widgets/item_actions_sheet.dart',
      'lib/features/inventory/presentation/widgets/reprice_sheet.dart',
      'lib/features/inventory/presentation/screens/inventory_screen/inventory_screen_bulk_bar.dart',
    ];

    final List<String> sources = paths
        .map((String path) => File(path).readAsStringSync())
        .toList();

    for (int index = 0; index < paths.length; index++) {
      final String source = sources[index];
      final String path = paths[index];
      expect(
        source,
        isNot(contains('SdSnackBarUtilsV3.success')),
        reason: path,
      );
    }

    expect(sources.join(), contains('SdSnackBarUtilsV3.error'));
  });
}
