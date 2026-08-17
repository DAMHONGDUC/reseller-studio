import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../mock_data/providers.dart';
import '../../domain/entities/plan_offering.dart';
import '../../domain/entities/subscription_status.dart';

/// Buying, restoring, and reading what is on sale (plan §25, §27).
///
/// **No receipt is handled here or anywhere above the repository.** This
/// orchestrates a sheet the store owns; what comes back is an entitlement,
/// which is the only thing the app is allowed to know.
class SubscriptionController extends Notifier<bool> {
  @override
  bool build() => false;

  /// What is on sale. Empty when billing is not configured — the screen
  /// renders its own message from that rather than an error.
  Future<List<PlanOffering>> loadOfferings() async {
    try {
      final List<PlanOffering> offerings = await ref
          .read(subscriptionRepositoryProvider)
          .offerings();

      SdLogger.info(
        LogTagConstant.subscription,
        'Offerings loaded',
        <String, int>{'count': offerings.length},
      );

      return offerings;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.subscription,
        'Failed to load offerings',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  /// Opens the store's purchase sheet.
  ///
  /// A cancelled purchase is **not** an error — the seller closed a sheet,
  /// the same rule sign-in follows (hard rule 1). It comes back as an
  /// unchanged status and the screen says nothing.
  Future<SubscriptionStatus> purchase(PlanOffering offering) async {
    state = true;
    SdLogger.action(
      LogTagConstant.subscription,
      'Purchase subscription',
      <String, String>{
        'productId': offering.productId,
        'plan': offering.plan.name,
        'period': offering.period.name,
      },
    );
    AppAnalytics.instance.subscriptionPurchaseStarted(
      plan: offering.plan.name,
      period: offering.period.name,
    );

    try {
      final SubscriptionStatus status = await ref
          .read(subscriptionRepositoryProvider)
          .purchase(offering);

      SdLogger.action(
        LogTagConstant.subscription,
        'Purchase finished',
        status.toLogData(),
      );

      // Only when it actually took: an unchanged plan means the seller closed
      // the store's sheet, and reporting that as an activation makes the
      // conversion figure a fiction.
      if (status.plan.isAtLeast(offering.plan)) {
        AppAnalytics.instance.subscriptionActivated(plan: status.plan.name);
      }

      return status;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.subscription,
        'Failed to purchase subscription',
        error: error,
        stackTrace: stackTrace,
        data: <String, String>{'productId': offering.productId},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// Required by App Store review for any app selling a subscription: a
  /// seller who reinstalls must be able to get their plan back without
  /// paying again.
  Future<SubscriptionStatus> restore() async {
    state = true;
    SdLogger.action(LogTagConstant.subscription, 'Restore purchases');

    try {
      final SubscriptionStatus status = await ref
          .read(subscriptionRepositoryProvider)
          .restore();

      SdLogger.action(
        LogTagConstant.subscription,
        'Restore finished',
        status.toLogData(),
      );

      return status;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.subscription,
        'Failed to restore purchases',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<SubscriptionController, bool>
subscriptionControllerProvider = NotifierProvider<SubscriptionController, bool>(
  SubscriptionController.new,
);
