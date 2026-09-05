import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import 'package:reseller_studio/features/orders/presentation/screens/orders_screen/orders_screen.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_allowance.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/providers.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// A list screen meters the allowance its own records count against, and
/// nothing else: a businesses meter on Inventory answers a question nobody
/// standing there is asking.
void main() {
  testWidgets('Inventory meters items and only items', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const InventoryScreen(),
      overrides: <Override>[
        currentPlanProvider.overrideWithValue(SellerPlan.free),
      ],
    );

    expect(
      find.text(PlanAllowance.items.meterTitle(SellerPlan.free)),
      findsOneWidget,
    );
    expect(find.byType(SdFreeLimitProgressV3), findsOneWidget);
  });

  testWidgets('Orders meters orders and only orders', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const OrdersScreen(),
      overrides: <Override>[
        currentPlanProvider.overrideWithValue(SellerPlan.free),
      ],
    );

    expect(
      find.text(PlanAllowance.orders.meterTitle(SellerPlan.free)),
      findsOneWidget,
    );
    expect(find.byType(SdFreeLimitProgressV3), findsOneWidget);
  });

  testWidgets('Premium is metered nowhere', (WidgetTester tester) async {
    await pumpScreen(
      tester,
      const InventoryScreen(),
      overrides: <Override>[
        currentPlanProvider.overrideWithValue(SellerPlan.premium),
      ],
    );

    expect(find.byType(SdFreeLimitProgressV3), findsNothing);
  });
}
