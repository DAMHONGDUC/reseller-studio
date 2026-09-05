import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_allowance.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/providers.dart';
import 'package:reseller_studio/features/workspace/presentation/screens/workspaces_screen/workspaces_screen.dart';
import 'package:system_design/index.dart';

import '../../support/pump_app.dart';

/// The screen that manages the list of businesses, as opposed to the switcher
/// sheet that picks one mid-task.
void main() {
  testWidgets('every business is listed and the current one is marked', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, const WorkspacesScreen());

    expect(find.text('Current'), findsOneWidget);
  });

  testWidgets('Free sees the ceiling it is about to spend', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const WorkspacesScreen(),
      overrides: <Override>[
        currentPlanProvider.overrideWithValue(SellerPlan.free),
      ],
    );

    expect(find.byType(SdFreeLimitProgressV3), findsOneWidget);
    expect(
      find.text(PlanAllowance.workspaces.meterTitle(SellerPlan.free)),
      findsOneWidget,
    );
  });

  testWidgets('Premium has no ceiling here either', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const WorkspacesScreen(),
      overrides: <Override>[
        currentPlanProvider.overrideWithValue(SellerPlan.premium),
      ],
    );

    expect(find.byType(SdFreeLimitProgressV3), findsNothing);
  });
}
