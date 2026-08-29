import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_card.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('In stock uses the same badge tone in Inventory and Detail', (
    WidgetTester tester,
  ) async {
    final Item item = Item(
      id: 'listed',
      title: 'Listed item',
      quantity: 1,
      status: ItemStatus.inStock,
      createdAt: testNow,
      listedAt: testNow,
    );
    await pumpScreen(tester, ItemCard(item: item, now: testNow));
    final SdBadgeToneV3 inventoryTone = tester
        .widget<SdBadgeV3>(find.widgetWithText(SdBadgeV3, 'In stock'))
        .tone;

    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-4'));
    final SdBadgeToneV3 detailTone = tester
        .widget<SdBadgeV3>(find.widgetWithText(SdBadgeV3, 'In stock'))
        .tone;

    expect(inventoryTone, SdBadgeToneV3.success);
    expect(detailTone, inventoryTone);
  });
}
