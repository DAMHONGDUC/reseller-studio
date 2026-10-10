import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
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

  for (final SellerPlan plan in SellerPlan.values) {
    testWidgets('${plan.label} has no business ceiling, so no meter', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const WorkspacesScreen(),
        overrides: <Override>[currentPlanProvider.overrideWithValue(plan)],
      );

      expect(find.byType(SdFreeLimitProgressV3), findsNothing);
    });
  }
}
