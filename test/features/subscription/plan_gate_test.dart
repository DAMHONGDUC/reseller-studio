import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_limits.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_feature.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';

/// Every expectation reads `PlanLimits`, so the test cannot keep passing
/// against a stale number copied into prose.
void main() {
  final PlanLimits free = PlanLimits.of(SellerPlan.free);

  test('Free has no ceiling: everything is free except export', () {
    // Owner's rule (`docs/rules/SUBSCRIPTION.md`): no count refuses Free.
    expect(free.items, isNull);
    expect(free.orders, isNull);
    expect(free.workspaces, isNull);
    expect(
      PlanGate.canAddItem(SellerPlan.free, currentItems: 100000),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddOrder(SellerPlan.free, currentOrders: 100000),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddWorkspace(SellerPlan.free, currentWorkspaces: 100000),
      PlanBlock.none,
    );
  });

  test('export is the one capability Premium sells', () {
    expect(PlanFeature.values, <PlanFeature>[PlanFeature.export]);
  });

  test('Premium removes every usage ceiling', () {
    final PlanLimits premium = PlanLimits.of(SellerPlan.premium);

    expect(premium.items, isNull);
    expect(premium.orders, isNull);
    expect(premium.workspaces, isNull);
    expect(
      PlanGate.canAddItem(SellerPlan.premium, currentItems: 100000),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddOrder(SellerPlan.premium, currentOrders: 100000),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddWorkspace(SellerPlan.premium, currentWorkspaces: 100000),
      PlanBlock.none,
    );
  });

  test('every paid feature belongs to Premium', () {
    for (final PlanFeature feature in PlanFeature.values) {
      expect(PlanGate.has(SellerPlan.free, feature), isFalse);
      expect(PlanGate.has(SellerPlan.premium, feature), isTrue);
    }
  });

  test('every block points to Premium', () {
    for (final PlanBlock block in PlanBlock.values) {
      expect(
        PlanGate.upgradeFor(block, from: SellerPlan.free),
        block == PlanBlock.none ? isNull : SellerPlan.premium,
      );
    }
  });

  test('Premium is what buys the answers, not permission to type', () {
    // The paid line is a capability, refused somewhere —
    // `paywall_promises_test.dart` pins where.
    for (final PlanFeature capability in PlanFeature.values) {
      expect(PlanGate.has(SellerPlan.free, capability), isFalse);
      expect(PlanGate.has(SellerPlan.premium, capability), isTrue);
    }
  });
}
