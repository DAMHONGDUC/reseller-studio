/// The marketplaces the architecture is built to support (plan §14).
///
/// **An enum rather than a free string**, because fee rates, listing field
/// requirements and sync behaviour all branch on it, and a typo in a string
/// would silently create a seventh marketplace with no fees and no
/// validation.
///
/// Adding one means adding a case here and a fee rate below — the compiler
/// then finds every switch that needs updating, which is the point.
///
/// **There is no `hasIntegration`.** Connecting to a platform is not a feature
/// of this app (owner's rule, hard rule 10), so a flag saying whether it could
/// be was a promise nothing kept.
enum Marketplace {
  ebay('eBay'),
  etsy('Etsy'),
  depop('Depop'),
  poshmark('Poshmark'),
  mercari('Mercari'),
  shopify('Shopify'),

  /// Sold outside any integration — a car boot sale, a friend, cash in hand.
  /// Not a platform, but it is where a lot of inventory actually goes, and
  /// excluding it would make the analytics disagree with the bank balance.
  other('Other');

  const Marketplace(this.displayName);

  /// Shown in the UI. **Not localized on purpose** — these are brand names,
  /// and "eBay" is "eBay" in every locale.
  final String displayName;

  /// The platform's commission, as a fraction of the sale price.
  ///
  /// **An estimate for planning only, never for accounting.** Real fees vary
  /// by category, seller tier, promotion and country, and the actual number
  /// arrives on the order from the integration. This exists so a sourcing
  /// decision can be made in a shop with no connection — see
  /// `PurchaseEvaluation`.
  ///
  /// Once an order is synced, use its reported fees. Never overwrite a real
  /// fee with this.
  double get estimatedFeeRate => switch (this) {
    Marketplace.ebay => 0.1325,
    Marketplace.etsy => 0.095,
    Marketplace.depop => 0.10,
    Marketplace.poshmark => 0.20,
    Marketplace.mercari => 0.10,
    Marketplace.shopify => 0.029,
    Marketplace.other => 0,
  };
}
