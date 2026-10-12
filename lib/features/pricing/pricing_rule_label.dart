import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/utils/text_input_utils.dart';
import 'domain/entities/pricing_rule.dart';
import 'domain/enums/price_rounding.dart';

/// A pricing rule in one line — what the rules list shows under each name.
final class PricingRuleLabel {
  /// `Cost × 2 + $5.00 · Ends in .99 · at least $3.00 profit`.
  static String summary(BuildContext context, PricingRule rule) {
    final List<String> parts = <String>[
      <String>[
        context.l10n.pricingRuleSummaryMultiply(
          TextInputUtils.decimalText(rule.multiplier),
        ),
        if (rule.fixedAdd != null)
          context.l10n.pricingRuleSummaryAdd(context.money(rule.fixedAdd)),
      ].join(' '),
      if (rule.rounding != PriceRounding.none) rule.rounding.label(context),
      if (rule.minProfit != null)
        context.l10n.pricingRuleSummaryMinProfit(context.money(rule.minProfit)),
    ];

    return parts.join(' · ');
  }
}
