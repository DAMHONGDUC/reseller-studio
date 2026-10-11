/// Which listings a pricing rule speaks for.
///
/// Stored by [name], so a case is never renamed once written.
enum PricingRuleScope {
  /// Every listing in the business.
  all,

  /// Listings on one marketplace record, named by `PricingRule.scopeId`.
  marketplace,

  /// Listings of items in one category, named by `PricingRule.scopeId`.
  category,
}
