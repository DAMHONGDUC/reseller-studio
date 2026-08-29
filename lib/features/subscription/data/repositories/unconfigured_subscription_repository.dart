import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/app_failure.dart';
import '../../domain/entities/plan_offering.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/repositories/subscription_repository.dart';

/// What the app uses until the owner has set up RevenueCat.
///
/// **Everyone is on Free and nothing fails.** The alternative — throwing from
/// the entitlement stream — would take down every screen that reads a plan,
/// over a question whose safe answer is "the cheapest tier". The same shape
/// the marketplaces and team screens already have: it renders, and it says
/// why it can do no more.
///
/// Buying is the one thing that must not silently no-op: a button that looks
/// like it worked and charged nothing is worse than a message.
class UnconfiguredSubscriptionRepository implements SubscriptionRepository {
  @override
  Stream<SubscriptionStatus> watchStatus() =>
      Stream<SubscriptionStatus>.value(SubscriptionStatus.free);

  @override
  Future<List<PlanOffering>> offerings() async => const <PlanOffering>[];

  @override
  Future<SubscriptionStatus> purchase(PlanOffering offering) async {
    SdLogger.warning(
      LogTagConstant.subscription,
      'Purchase attempted with billing not configured',
      <String, String>{'productId': offering.productId},
    );

    throw const AppFailure(
      AppFailureKind.invalidData,
      technicalMessage: 'RevenueCat is not configured — see RELEASE_ACTIONS.md',
    );
  }

  @override
  Future<SubscriptionStatus> restore() async => SubscriptionStatus.free;

  /// Nothing to identify to. Silent rather than logged: this runs on every
  /// sign-in of every build without billing, which is most of them.
  @override
  Future<void> identify(String uid) async {}

  @override
  Future<void> forget() async {}
}
