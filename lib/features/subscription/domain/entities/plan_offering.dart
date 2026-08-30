import '../enums/seller_plan.dart';
import 'plan_intro_offer.dart';

/// How long one purchase lasts.
enum BillingPeriod { monthly, yearly }

/// One buyable product, as the store described it (plan §27).
///
/// **The price is the store's own formatted string, not a `Money`.** Every
/// other amount in this app is integer minor units (hard rule 4) because the
/// app computes with it; this one is never summed, never compared and never
/// converted — it is quoted. The store has already localised the currency,
/// the symbol's position and the tax treatment for the seller's storefront,
/// and re-deriving any of that is how a price on screen stops matching the
/// price on the receipt.
class PlanOffering {
  const PlanOffering({
    required this.productId,
    required this.plan,
    required this.period,
    required this.formattedPrice,
    this.introOffer,
  });

  /// The store product identifier. Opaque here — only the billing SDK's
  /// implementation gives it meaning.
  final String productId;

  final SellerPlan plan;
  final BillingPeriod period;

  /// Ready to render, e.g. `$9.99` or `£7.99`.
  final String formattedPrice;

  /// What the store offers before that price, when it offers anything and
  /// this seller is still eligible for it. Null is the normal case.
  final PlanIntroOffer? introOffer;

  /// The same product with its introductory offer dropped — what a seller who
  /// has already used one is actually buying.
  PlanOffering withoutIntroOffer() => PlanOffering(
    productId: productId,
    plan: plan,
    period: period,
    formattedPrice: formattedPrice,
  );
}
