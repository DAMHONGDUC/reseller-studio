part of 'pricing_rule_detail_screen.dart';

/// The price the rule gives a cost the seller types — the rule explained by
/// running it, rather than by a paragraph about multipliers.
class _Preview extends ConsumerWidget {
  const _Preview({
    required this.rule,
    required this.cost,
    required this.currency,
    required this.onChanged,
  });

  final PricingRule? rule;
  final TextEditingController cost;
  final String currency;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PricingRule? current = rule;
    final PricingQuote? quote = current == null
        ? null
        : PricingRuleCalculator.quote(
            cost: Money.tryParse(cost.text, currency),
            rule: current,
            feeRate: ref.watch(planningFeeRateProvider),
          );
    final TextStyle style = context.textTheme3.bodyMedium!.tabular3;

    return AppSection(
      title: context.l10n.pricingRulePreviewTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MoneyField(
            label: context.l10n.pricingRulePreviewCostLabel,
            controller: cost,
            currency: currency,
            textInputAction: TextInputAction.done,
            onChanged: (String _) => onChanged(),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          AnimatedSwitcher(
            duration: SdMotionV3.fast,
            child: Text(
              quote == null
                  ? context.l10n.pricingRulePreviewEmpty
                  : context.l10n.pricingRulePreviewResult(
                      context.money(quote.price),
                      context.money(quote.expectedProfit),
                    ),
              key: ValueKey<int?>(quote?.price.minor),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
