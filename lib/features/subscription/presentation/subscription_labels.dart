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
  /// Delegates to the enum's own display, which is where a name a second
  /// feature needs has to live — More reads it too, and it may not import
  /// this file (`presentation/` is private to its feature).
  static String name(SellerPlan plan) => plan.label;

  static String tagline(SellerPlan plan) => switch (plan) {
    SellerPlan.free => 'Fifty items and thirty sales a month, free',
    SellerPlan.premium => 'The answers: tax, payouts, and what to buy next',
  };

  /// **Two or three words each.** The paywall lists these in two columns, and
  /// a line that wraps there costs the sheet a row of height for one word.
  /// "Businesses" rather than "workspaces": that is what the app calls one
  /// everywhere the seller can read it.
  static String feature(PlanFeature feature) => switch (feature) {
    PlanFeature.taxExport => 'Tax pack export',
    PlanFeature.payoutReconciliation => 'Payout chasing',
  };

  static String period(BillingPeriod period) => switch (period) {
    BillingPeriod.monthly => 'per month',
    BillingPeriod.yearly => 'per year',
  };

  /// What one option card is titled. Deliberately not [period]: a card headed
  /// "per year" reads as a price fragment, and the price is the line under it.
  static String periodName(BillingPeriod period) => switch (period) {
    BillingPeriod.monthly => 'Monthly',
    BillingPeriod.yearly => 'Yearly',
  };

  /// The mark on the option the paywall recommends.
  static const String bestValue = 'Best value';

  /// What a plan holds, one line per ceiling.
  ///
  /// Reads the ceilings from [PlanLimits] rather than repeating them, so a
  /// price change never leaves the sales copy claiming the old number.
  static List<String> allowances(SellerPlan plan) {
    final PlanLimits limits = PlanLimits.of(plan);

    return <String>[
      _countLine(limits.items, 'item', 'Unlimited items'),
      _countLine(limits.orders, 'order', 'Unlimited orders'),
      _countLine(limits.workspaces, 'business', 'Unlimited businesses'),
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
        '$planName holds ${limits.items} items in total. '
            'Upgrade to add more.',
      // Says the window, because the wall is temporary and a seller who does
      // not know that reads it as the end of the road.
      PlanBlock.orderLimit =>
        '$planName records ${limits.orders} orders every 30 days. '
            'The oldest one drops out soon — or upgrade now.',
      PlanBlock.workspaceLimit =>
        '$planName includes ${limits.workspaces} business. Upgrade to create more.',
      PlanBlock.featureLocked => 'This is part of a higher plan.',
    };
  }

  /// A short, stable name for the analytics `reason` parameter. Deliberately
  /// not the sentence above — copy changes, and a metric whose key changes
  /// with the copy is a metric with a hole in it.
  static String blockKey(PlanBlock block) => block.name;

  static String _countLine(int? limit, String noun, String unlimited) =>
      limit == null ? unlimited : '$limit $noun${limit == 1 ? '' : 's'}';
}
