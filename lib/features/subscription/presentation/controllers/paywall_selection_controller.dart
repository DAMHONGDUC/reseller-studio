import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/plan_offering.dart';
import '../../domain/services/plan_offering_catalogue.dart';

/// Which billing period the paywall has selected.
///
/// **The choice is state, and one button buys it.** Two purchase buttons meant
/// the price a seller read and the product their thumb reached for were two
/// different decisions; here the selected card and the CTA read the same
/// value, so they cannot disagree.
class PaywallSelectionController extends Notifier<BillingPeriod> {
  @override
  BillingPeriod build() => PlanOfferingCatalogue.recommended;

  void select(BillingPeriod period) {
    if (state == period) return;

    SdLogger.action(
      LogTagConstant.subscription,
      'Paywall period selected',
      <String, String>{'period': period.name},
    );

    state = period;
  }
}

final NotifierProvider<PaywallSelectionController, BillingPeriod>
paywallSelectionProvider =
    NotifierProvider<PaywallSelectionController, BillingPeriod>(
      PaywallSelectionController.new,
    );
