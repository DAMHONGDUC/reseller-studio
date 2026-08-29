import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/subscription/domain/entities/plan_limits.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_feature.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';

/// Every boundary reads its expected ceiling from `PlanLimits`, so the test
/// cannot keep passing against a stale number copied into prose.
void main() {
  final PlanLimits free = PlanLimits.of(SellerPlan.free);

  test('Free allows the last item and blocks the next one', () {
    expect(
      PlanGate.canAddItem(SellerPlan.free, currentItems: free.items! - 1),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddItem(SellerPlan.free, currentItems: free.items!),
      PlanBlock.itemLimit,
    );
  });

  test('Free allows the last order and blocks the next one', () {
    expect(
      PlanGate.canAddOrder(SellerPlan.free, currentOrders: free.orders! - 1),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddOrder(SellerPlan.free, currentOrders: free.orders!),
      PlanBlock.orderLimit,
    );
  });

  test('Free allows its first business and blocks another one', () {
    expect(
      PlanGate.canAddWorkspace(
        SellerPlan.free,
        currentWorkspaces: free.workspaces! - 1,
      ),
      PlanBlock.none,
    );
    expect(
      PlanGate.canAddWorkspace(
        SellerPlan.free,
        currentWorkspaces: free.workspaces!,
      ),
      PlanBlock.workspaceLimit,
    );
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
}
