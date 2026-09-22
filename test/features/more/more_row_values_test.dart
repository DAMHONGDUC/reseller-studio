import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:reseller_studio/features/auth/providers.dart';
import 'package:reseller_studio/features/more/presentation/screens/more_screen/more_screen.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/providers.dart';

import '../../support/pump_app.dart';

/// **The meters are not here.** They used to be: More was the overview, and
/// this file pinned every capped allowance on it. More was redesigned and the
/// meters went with the lists they are about — Subscription for the whole set,
/// Workspaces, Inventory and Orders for the one each holds — and the
/// assertions moved to `test/features/subscription/plan_meters_test.dart`.
/// What is left here is what More itself still says.
void main() {
  testWidgets('More names the plan and the session without opening either', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const MoreScreen(),
      overrides: <Override>[
        isSignedInProvider.overrideWithValue(true),
        currentPlanProvider.overrideWithValue(SellerPlan.free),
      ],
    );

    final Finder scrollable = find.byType(Scrollable).first;
    final Finder planName = find.text(SellerPlan.free.label);

    await tester.scrollUntilVisible(planName, 300, scrollable: scrollable);

    expect(planName, findsOneWidget);
    expect(find.text('Signed in'), findsOneWidget);
  });

  testWidgets('signed out, the Settings row says so', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const MoreScreen(),
      overrides: <Override>[isSignedInProvider.overrideWithValue(false)],
    );

    expect(find.text('Not signed in'), findsOneWidget);
  });
}
