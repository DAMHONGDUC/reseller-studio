import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/features/subscription/domain/enums/plan_feature.dart';
import 'package:reseller_studio/features/subscription/domain/enums/seller_plan.dart';
import 'package:reseller_studio/features/subscription/domain/services/plan_gate.dart';

/// Every line the paywall sells has something in the app that refuses it.
///
/// **The paywall is generated from `PlanFeature`**, so a value with no gate
/// behind it is a promise nothing keeps — and six of them were exactly that:
/// advanced analytics, CSV reports, automation, team members, multiple
/// businesses and roles. Two of those never existed as code at all, one was
/// free one screen over, and one was the workspace ceiling sold twice under
/// two names.
///
/// This test is the thing that stops the list growing back ahead of the
/// gates: adding a value here fails until something reads it.
void main() {
  /// Where each capability is refused. Kept in the test rather than the enum
  /// because it is an assertion about the app, not a fact about the plan.
  const Map<PlanFeature, String> gatedAt = <PlanFeature, String>{
    PlanFeature.export:
        'tax_screen_export.dart, and every row on the Reports screen',
    PlanFeature.payoutReconciliation: 'payouts_screen.dart',
  };

  test('every sold capability names a gate', () {
    expect(
      PlanFeature.values.toSet(),
      gatedAt.keys.toSet(),
      reason:
          'a capability on the paywall with no gate is a promise the product '
          'does not keep — gate it, or take it off the list',
    );
  });

  test('every capability belongs to Premium, so the paywall has one step', () {
    for (final PlanFeature feature in PlanFeature.values) {
      expect(PlanGate.has(SellerPlan.free, feature), isFalse);
      expect(PlanGate.has(SellerPlan.premium, feature), isTrue);
    }
  });
}
