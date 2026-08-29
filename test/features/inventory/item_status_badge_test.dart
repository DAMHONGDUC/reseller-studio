import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import 'package:reseller_studio/features/inventory/presentation/widgets/item_card.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **One value, one colour, wherever it is drawn** — owner's rule. The row and
/// the detail screen show the same item; a status that changed shade between
/// them would be the seller learning the palette twice.
void main() {
  testWidgets('In stock is the same colour in Inventory and Item Detail', (
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

    late Color expected;

    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) {
          expected = ItemStatus.inStock.color(context);

          return ItemCard(item: item, now: testNow);
        },
      ),
    );

    final Color inventoryColor = tester
        .widget<SdTagV3>(find.widgetWithText(SdTagV3, 'In stock'))
        .color;

    await pumpScreen(tester, const ItemDetailScreen(itemId: 'itm-11'));

    final Color? detailColor = tester
        .widget<SdBadgeV3>(find.widgetWithText(SdBadgeV3, 'In stock'))
        .color;

    expect(inventoryColor, expected);
    expect(detailColor, expected);
  });
}
