import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_tag_hue.dart';

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

/// How a scope reads and which hue its tag wears.
extension PricingRuleScopeDisplay on PricingRuleScope {
  String label(BuildContext context) => switch (this) {
    PricingRuleScope.all => context.l10n.pricingRuleScopeAll,
    PricingRuleScope.marketplace => context.l10n.pricingRuleScopeMarketplace,
    PricingRuleScope.category => context.l10n.pricingRuleScopeCategory,
  };

  Color color(BuildContext context) => switch (this) {
    PricingRuleScope.all => AppTagHue.grey,
    PricingRuleScope.marketplace => AppTagHue.blue,
    PricingRuleScope.category => AppTagHue.violet,
  }.of(context);
}
