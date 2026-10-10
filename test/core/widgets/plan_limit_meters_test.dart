import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// A meter is drawn only for a ceiling, and no plan has one: everything is
/// free except export (`docs/rules/SUBSCRIPTION.md`).
void main() {
  const Map<String, Widget> screens = <String, Widget>{
    'Inventory': InventoryScreen(),
    'Orders': OrdersScreen(),
  };

  for (final SellerPlan plan in SellerPlan.values) {
    for (final MapEntry<String, Widget> screen in screens.entries) {
      testWidgets('${plan.label} is metered nowhere on ${screen.key}', (
        WidgetTester tester,
      ) async {
        await pumpScreen(
          tester,
          screen.value,
          overrides: <Override>[currentPlanProvider.overrideWithValue(plan)],
        );

        expect(find.byType(SdFreeLimitProgressV3), findsNothing);
      });
    }
  }
}
