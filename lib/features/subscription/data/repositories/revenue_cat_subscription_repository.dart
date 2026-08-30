import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:system_design/common.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../domain/entities/plan_offering.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/enums/seller_plan.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../revenue_cat_product_mapper.dart';

/// Entitlement read from RevenueCat (plan §27).
///
/// **Nothing above this class knows a receipt exists.** RevenueCat verifies
/// with the store and answers a question — "what is this seller entitled
/// to?" — and only that answer crosses into `domain/`. No transaction id, no
/// receipt and no store token is returned or logged (hard rule 9).
///
/// This is a *cache for rendering*. `firestore.rules` reads the entitlement a
/// Cloud Function mirrored from RevenueCat's webhook, because a rule cannot
/// ask an SDK a question and a client that could write its own plan is a
/// paywall with a free bypass.
class RevenueCatSubscriptionRepository implements SubscriptionRepository {
  @override
  Stream<SubscriptionStatus> watchStatus() {
    final StreamController<SubscriptionStatus> controller =
        StreamController<SubscriptionStatus>.broadcast();

    void onUpdate(CustomerInfo info) => controller.add(_statusFrom(info));

    Purchases.addCustomerInfoUpdateListener(onUpdate);
    controller.onCancel = () =>
        Purchases.removeCustomerInfoUpdateListener(onUpdate);

    // The listener only fires on a *change*, so without this first read a
    // seller who bought last month opens the app on Free until something
    // moves.
    unawaited(_emitCurrent(controller));

    return controller.stream;
  }

  @override
  Future<List<PlanOffering>> offerings() =>
      FailureMapper.guard('load subscription offerings', () async {
        final Offerings offerings = await Purchases.getOfferings();
        final Offering? offering = _activeOffering(offerings);
        final List<Package> packages =
            offering?.availablePackages ?? const <Package>[];
        final List<PlanOffering> rows = await _withEligibleOffers(
          packages.map(RevenueCatProductMapper.offering).nonNulls.toList(),
        );

        if (rows.isEmpty) {
          // An empty paywall is otherwise silent: nothing threw, the store just
          // had nothing this build can sell.
          SdLogger.warning(
            LogTagConstant.subscription,
            'No sellable package in the offering',
            _storeDiagnostics(offerings, offering, packages),
          );

          return rows;
        }

        SdLogger.info(
          LogTagConstant.subscription,
          'Subscription offerings loaded',
          <String, Object>{
            'offering': offering?.identifier ?? '',
            'packages': packages.length,
            'mapped': rows.length,
            'withIntroOffer': rows
                .where((PlanOffering row) => row.introOffer != null)
                .length,
          },
        );

        return rows;
      });

  @override
  Future<SubscriptionStatus> purchase(PlanOffering offering) =>
      FailureMapper.guard('purchase a subscription', () async {
        final Package? package = await _packageFor(offering);

        if (package == null) {
          throw AppFailure(
            AppFailureKind.notFound,
            technicalMessage: 'No package for ${offering.productId}',
          );
        }

        SdLogger.action(
          LogTagConstant.subscription,
          'Subscription purchase started',
          <String, String>{
            'productId': offering.productId,
            'plan': offering.plan.name,
          },
        );

        final PurchaseResult result = await Purchases.purchase(
          PurchaseParams.package(package),
        );

        final SubscriptionStatus status = _statusFrom(result.customerInfo);

        SdLogger.action(
          LogTagConstant.subscription,
          'Subscription purchase finished',
          status.toLogData(),
        );

        return status;
      });

  @override
  Future<SubscriptionStatus> restore() =>
      FailureMapper.guard('restore purchases', () async {
        final CustomerInfo info = await Purchases.restorePurchases();
        final SubscriptionStatus status = _statusFrom(info);

        SdLogger.action(
          LogTagConstant.subscription,
          'Purchases restored',
          status.toLogData(),
        );

        return status;
      });

  /// **This is what makes the webhook possible.** RevenueCat's `app_user_id`
  /// becomes the Firebase uid, which is what the Cloud Function looks the
  /// seller up by when it mirrors entitlement into Firestore. Without it the
  /// id is anonymous and the backend can never connect a payment to an
  /// account.
  ///
  /// The uid is not a credential — it is already in every document's
  /// `createdBy` — so logging it is within hard rule 9.
  @override
  Future<void> identify(String uid) =>
      FailureMapper.guard('identify for billing', () async {
        await Purchases.logIn(uid);

        SdLogger.info(
          LogTagConstant.subscription,
          'Billing identified',
          <String, String>{'uid': uid},
        );
      });

  @override
  Future<void> forget() =>
      FailureMapper.guard('forget billing identity', () async {
        await Purchases.logOut();

        SdLogger.info(LogTagConstant.subscription, 'Billing identity cleared');
      });

  /// The first value on the stream.
  ///
  /// Its own try/catch rather than `FailureMapper.guard`: a stream that
  /// errored here would leave the whole app looking broken over a question
  /// whose safe answer is "Free". The failure is logged and the seller keeps
  /// working (hard rule 8).
  Future<void> _emitCurrent(
    StreamController<SubscriptionStatus> controller,
  ) async {
    try {
      final CustomerInfo info = await Purchases.getCustomerInfo();

      if (controller.isClosed) return;

      controller.add(_statusFrom(info));
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.subscription,
        'Failed to read entitlement — falling back to Free',
        error: error,
        stackTrace: stackTrace,
      );

      if (!controller.isClosed) controller.add(SubscriptionStatus.free);
    }
  }

  /// Finds the store package a domain offering came from.
  ///
  /// Looked up again rather than carried on `PlanOffering`, which would mean
  /// a domain entity holding an SDK object.
  Future<Package?> _packageFor(PlanOffering offering) async {
    final Offerings offerings = await Purchases.getOfferings();

    return _activeOffering(offerings)?.availablePackages
        .where(
          (Package package) =>
              package.storeProduct.identifier == offering.productId,
        )
        .firstOrNull;
  }

  /// Drops an introductory offer the store will not honour for this seller.
  ///
  /// Its own try/catch rather than a failure: a paywall that cannot answer
  /// "eligible?" still has a price to sell. An unknown answer counts as
  /// eligible because Android answers unknown for everyone, and the store
  /// refuses a second trial itself.
  Future<List<PlanOffering>> _withEligibleOffers(
    List<PlanOffering> rows,
  ) async {
    final List<String> withOffer = rows
        .where((PlanOffering row) => row.introOffer != null)
        .map((PlanOffering row) => row.productId)
        .toList();

    if (withOffer.isEmpty) return rows;

    try {
      final Map<String, IntroEligibility> eligibility =
          await Purchases.checkTrialOrIntroductoryPriceEligibility(withOffer);

      return rows
          .map(
            (PlanOffering row) =>
                _isEligible(eligibility, row) ? row : row.withoutIntroOffer(),
          )
          .toList();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.subscription,
        'Failed to check trial eligibility — quoting the store as it came',
        error: error,
        stackTrace: stackTrace,
        data: <String, int>{'products': withOffer.length},
      );

      return rows;
    }
  }

  static bool _isEligible(
    Map<String, IntroEligibility> eligibility,
    PlanOffering row,
  ) =>
      eligibility[row.productId]?.status !=
      IntroEligibilityStatus.introEligibilityStatusIneligible;

  /// The offering this build sells, falling back to whichever one
  /// RevenueCat marks current.
  ///
  /// A renamed offering on the dashboard would otherwise empty the paywall
  /// with nothing thrown and nothing logged, and `current` is the answer
  /// every other RevenueCat client defaults to.
  static Offering? _activeOffering(Offerings offerings) =>
      offerings.getOffering(AppEnv.revenueCatOffering) ?? offerings.current;

  /// What the next person would otherwise reproduce the run to find out:
  /// which offering was asked for, and what the store actually returned.
  static Map<String, Object> _storeDiagnostics(
    Offerings offerings,
    Offering? offering,
    List<Package> packages,
  ) => <String, Object>{
    'asked': AppEnv.revenueCatOffering,
    'used': offering?.identifier ?? 'none',
    'available': offerings.all.keys.toList(),
    'packages': packages.map(_describe).toList(),
  };

  /// Enough of a package to see why the mapper dropped it — a custom type
  /// with a period this app does not sell is the usual answer.
  static String _describe(Package package) =>
      '${package.identifier}/${package.packageType.name}/'
      '${package.storeProduct.subscriptionPeriod ?? "none"}';

  /// Reads the one entitlement configured for this build.
  static SubscriptionStatus _statusFrom(CustomerInfo info) {
    final EntitlementInfo? premium =
        info.entitlements.active[AppEnv.revenueCatEntitlement];

    if (premium == null) return SubscriptionStatus.free;

    return SubscriptionStatus(
      plan: SellerPlan.premium,
      source: _sourceFrom(premium.store),
      renewsAt: DateTime.tryParse(premium.expirationDate ?? ''),
      willRenew: premium.willRenew,
      // A billing issue is a prompt to fix a card, never a downgrade — the
      // store is still retrying and access continues.
      isInGracePeriod: premium.billingIssueDetectedAt != null,
    );
  }

  static SubscriptionSource _sourceFrom(Store store) => switch (store) {
    Store.appStore || Store.macAppStore => SubscriptionSource.appStore,
    Store.playStore || Store.amazon => SubscriptionSource.playStore,
    Store.promotional => SubscriptionSource.promotional,
    _ => SubscriptionSource.none,
  };
}
