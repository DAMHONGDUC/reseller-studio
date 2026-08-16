import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/plan_offering.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/enums/seller_plan.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../subscription_product_constant.dart';

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
        final List<Package> packages =
            offerings.current?.availablePackages ?? const <Package>[];

        final List<PlanOffering> rows = packages
            .map(_offeringFrom)
            .nonNulls
            .toList();

        AppLogger.info('Subscription offerings loaded', <String, Object>{
          'packages': packages.length,
          'mapped': rows.length,
        });

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

        AppLogger.action('Subscription purchase started', <String, String>{
          'productId': offering.productId,
          'plan': offering.plan.name,
        });

        final PurchaseResult result = await Purchases.purchase(
          PurchaseParams.package(package),
        );

        final SubscriptionStatus status = _statusFrom(result.customerInfo);

        AppLogger.action('Subscription purchase finished', status.toLogData());

        return status;
      });

  @override
  Future<SubscriptionStatus> restore() =>
      FailureMapper.guard('restore purchases', () async {
        final CustomerInfo info = await Purchases.restorePurchases();
        final SubscriptionStatus status = _statusFrom(info);

        AppLogger.action('Purchases restored', status.toLogData());

        return status;
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
      AppLogger.error(
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

    return offerings.current?.availablePackages
        .where(
          (Package package) =>
              package.storeProduct.identifier == offering.productId,
        )
        .firstOrNull;
  }

  /// **Reads the highest active entitlement, not the first.** A seller who
  /// upgraded mid-period holds both for a while, and picking either at random
  /// is how Business briefly renders as Pro.
  static SubscriptionStatus _statusFrom(CustomerInfo info) {
    final Map<String, EntitlementInfo> active = info.entitlements.active;

    EntitlementInfo? best;
    SellerPlan plan = SellerPlan.free;

    for (final MapEntry<String, EntitlementInfo> entry in active.entries) {
      final SellerPlan? granted =
          SubscriptionProductConstant.planByEntitlement[entry.key];

      if (granted == null) continue;
      if (best != null && !granted.isAtLeast(plan)) continue;

      best = entry.value;
      plan = granted;
    }

    if (best == null) return SubscriptionStatus.free;

    return SubscriptionStatus(
      plan: plan,
      source: _sourceFrom(best.store),
      renewsAt: DateTime.tryParse(best.expirationDate ?? ''),
      willRenew: best.willRenew,
      // A billing issue is a prompt to fix a card, never a downgrade — the
      // store is still retrying and access continues.
      isInGracePeriod: best.billingIssueDetectedAt != null,
    );
  }

  static SubscriptionSource _sourceFrom(Store store) => switch (store) {
    Store.appStore || Store.macAppStore => SubscriptionSource.appStore,
    Store.playStore || Store.amazon => SubscriptionSource.playStore,
    Store.promotional => SubscriptionSource.promotional,
    _ => SubscriptionSource.none,
  };

  /// Null for a package this app has no plan for — a promo product, or one
  /// added to the dashboard before the app knew about it. Skipped rather than
  /// guessed.
  static PlanOffering? _offeringFrom(Package package) {
    final SellerPlan? plan = _planFor(package);

    if (plan == null) return null;

    return PlanOffering(
      productId: package.storeProduct.identifier,
      plan: plan,
      period: package.packageType == PackageType.annual
          ? BillingPeriod.yearly
          : BillingPeriod.monthly,
      formattedPrice: package.storeProduct.priceString,
    );
  }

  /// Which plan a package sells, read off the product identifier.
  ///
  /// The identifier is expected to contain the plan's name — `pro_monthly`,
  /// `business_yearly`. That is a convention with the dashboard, so it is
  /// checked rather than assumed: an unrecognised product is dropped, never
  /// sold as the wrong tier.
  static SellerPlan? _planFor(Package package) {
    final String id = package.storeProduct.identifier.toLowerCase();

    for (final SellerPlan plan in SellerPlan.values.reversed) {
      if (plan != SellerPlan.free && id.contains(plan.name)) return plan;
    }

    return null;
  }
}
