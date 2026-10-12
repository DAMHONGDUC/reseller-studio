part of 'pricing_rule_detail_screen.dart';

/// Which listings the rule speaks for, and — for one marketplace or one
/// category — which one.
class _ScopeField extends ConsumerWidget {
  const _ScopeField({
    required this.scope,
    required this.scopeId,
    required this.onScope,
    required this.onScopeId,
  });

  final PricingRuleScope scope;
  final String? scopeId;
  final ValueChanged<PricingRuleScope> onScope;
  final ValueChanged<String> onScopeId;

  Future<void> _pick(
    BuildContext context,
    List<PickerOption<String>> options,
    String title,
  ) async {
    final String? picked = await OptionPickerSheet.show<String>(
      context,
      title: title,
      options: options,
      selected: scopeId,
    );

    if (picked != null) onScopeId(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PickerOption<String>> options = switch (scope) {
      PricingRuleScope.all => const <PickerOption<String>>[],
      PricingRuleScope.marketplace => <PickerOption<String>>[
        for (final Marketplace marketplace in ref.watch(
          activeMarketplacesProvider,
        ))
          PickerOption<String>(value: marketplace.id, label: marketplace.name),
      ],
      PricingRuleScope.category => <PickerOption<String>>[
        for (final ItemCategory category
            in ref.watch(categoriesProvider).value ?? const <ItemCategory>[])
          if (!category.isDeleted)
            PickerOption<String>(value: category.id, label: category.name),
      ],
    };
    final String targetLabel = scope == PricingRuleScope.marketplace
        ? context.l10n.pricingRuleScopeTargetMarketplace
        : context.l10n.pricingRuleScopeTargetCategory;
    final String? value = options
        .where((PickerOption<String> option) => option.value == scopeId)
        .firstOrNull
        ?.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ChoiceField<PricingRuleScope>(
          label: context.l10n.pricingRuleScopeLabel,
          values: PricingRuleScope.values,
          selected: scope,
          labelOf: (PricingRuleScope value) => value.label(context),
          colorOf: (PricingRuleScope value) => value.color(context),
          onSelected: onScope,
        ),
        if (scope != PricingRuleScope.all) ...<Widget>[
          SizedBox(height: SdContentPaddingV3.listItemGap),
          PickerField(
            label: targetLabel,
            value: value,
            isRequired: true,
            onTap: () => _pick(context, options, targetLabel),
          ),
        ],
      ],
    );
  }
}
