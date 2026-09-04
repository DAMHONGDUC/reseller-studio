import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/widgets/item_card.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// **One value, one colour, wherever it is drawn** — owner's rule.
///
/// The colour lives on the enum as an extension, so the tag on the item form
/// and the compact badge on the card cannot come out as two shades of nearly
/// the same thing.
void main() {
  Item itemWith(ItemStatus status, ItemCondition condition) => Item(
    id: 'itm-1',
    title: 'Vintage jacket',
    quantity: 1,
    status: status,
    createdAt: testNow,
    condition: condition,
  );

  testWidgets('the card paints each tag the colour its enum gives', (
    WidgetTester tester,
  ) async {
    late Color statusColor;
    late Color conditionColor;

    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) {
          statusColor = ItemStatus.archived.color(context);
          conditionColor = ItemCondition.forParts.color(context);

          return ItemCard(
            item: itemWith(ItemStatus.archived, ItemCondition.forParts),
            now: testNow,
          );
        },
      ),
    );

    expect(
      tester
          .widget<SdBadgeV3>(find.widgetWithText(SdBadgeV3, 'Archived'))
          .color,
      statusColor,
    );
    expect(
      tester
          .widget<SdBadgeV3>(find.widgetWithText(SdBadgeV3, 'For parts'))
          .color,
      conditionColor,
    );
  });

  testWidgets('no two statuses share a colour', (WidgetTester tester) async {
    late Set<Color> colors;

    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) {
          colors = ItemStatus.values
              .map((ItemStatus status) => status.color(context))
              .toSet();

          return const SizedBox.shrink();
        },
      ),
    );

    // A set that shared a hue would make the radios on the form a shape test
    // rather than a colour one, which is the reason the palette exists.
    expect(colors, hasLength(ItemStatus.values.length));
  });

  testWidgets('no two condition grades share a colour', (
    WidgetTester tester,
  ) async {
    late Set<Color> colors;

    await pumpScreen(
      tester,
      Builder(
        builder: (BuildContext context) {
          colors = ItemCondition.values
              .map((ItemCondition condition) => condition.color(context))
              .toSet();

          return const SizedBox.shrink();
        },
      ),
    );

    expect(colors, hasLength(ItemCondition.values.length));
  });
}
