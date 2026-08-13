import '../domain/entities/plan_limits.dart';
import '../domain/entities/plan_offering.dart';
import '../domain/enums/plan_feature.dart';
import '../domain/enums/seller_plan.dart';
import '../domain/services/plan_gate.dart';

/// What the plans are called on screen, and what each one says it gives.
///
/// **Its own class, out of the widgets.** Every screen that mentions a plan —
/// Subscription, the paywall sheet, a blocked create action — has to call it
/// the same thing, and a name typed into three widgets is a rename that gets
/// done twice.
///
/// English only for now: hard rule 7 defers the *translation*, not the ARB
/// key, and these move into `app_en.arb` with the rest of the backfill.
final class SubscriptionLabels {
  static String name(SellerPlan plan) => switch (plan) {
    SellerPlan.free => 'Free',
    SellerPlan.pro => 'Pro',
    SellerPlan.business => 'Business',
  };

  static String tagline(SellerPlan plan) => switch (plan) {
    SellerPlan.free => 'Enough to run a small shelf',
    SellerPlan.pro => 'For a seller doing this properly',
    SellerPlan.business => 'For a team, and more than one shop',
  };

  static String feature(PlanFeature feature) => switch (feature) {
    PlanFeature.advancedAnalytics => 'Every analytics drill-down',
    PlanFeature.reports => 'CSV reports and exports',
    PlanFeature.automation => 'Automation',
    PlanFeature.team => 'Team members',
    PlanFeature.multipleWorkspaces => 'Multiple workspaces',
    PlanFeature.advancedPermissions => 'Roles and permissions',
  };

  static String period(BillingPeriod period) => switch (period) {
    BillingPeriod.monthly => 'per month',
    BillingPeriod.yearly => 'per year',
  };

  /// What a plan holds, one line per ceiling.
  ///
  /// Reads the ceilings from [PlanLimits] rather than repeating them, so a
  /// price change never leaves the sales copy claiming the old number.
  static List<String> allowances(SellerPlan plan) {
    final PlanLimits limits = PlanLimits.of(plan);

    return <String>[
      _countLine(limits.items, 'item', 'Unlimited items'),
      _countLine(
        limits.activeListings,
        'active listing',
        'Unlimited active listings',
      ),
      _countLine(
        limits.marketplaces,
        'marketplace connection',
        'Unlimited marketplace connections',
      ),
      for (final PlanFeature capability in PlanFeature.values)
        if (PlanGate.has(plan, capability)) feature(capability),
    ];
  }

  /// Why the seller was stopped, in one sentence they can act on.
  ///
  /// **Names the ceiling they hit.** "Free holds 50 items" is a reason to
  /// upgrade; "limit reached" is a reason to close the app.
  static String blockReason(PlanBlock block, SellerPlan plan) {
    final PlanLimits limits = PlanLimits.of(plan);
    final String planName = name(plan);

    return switch (block) {
      PlanBlock.none => '',
      PlanBlock.itemLimit =>
        '$planName holds ${limits.items} items. Upgrade to add more.',
      PlanBlock.listingLimit =>
        '$planName allows ${limits.activeListings} active listings at once.',
      PlanBlock.marketplaceLimit =>
        '$planName connects to ${limits.marketplaces} marketplace'
            '${limits.marketplaces == 1 ? '' : 's'}.',
      PlanBlock.memberLimit =>
        '$planName includes ${limits.members} seats. Upgrade for more.',
      PlanBlock.featureLocked => 'This is part of a higher plan.',
    };
  }

  /// A short, stable name for the analytics `reason` parameter. Deliberately
  /// not the sentence above — copy changes, and a metric whose key changes
  /// with the copy is a metric with a hole in it.
  static String blockKey(PlanBlock block) => block.name;

  static String _countLine(int? limit, String noun, String unlimited) =>
      limit == null
      ? unlimited
      : '$limit $noun${limit == 1 ? '' : 's'}';
}
