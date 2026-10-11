import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../domain/entities/pricing_rule.dart';
import '../../../pricing_rule_label.dart';
import '../../../providers.dart';

/// Every pricing rule the business keeps (plan §15, `docs/DROPSHIPPING_PLAN.md`).
class PricingRulesScreen extends ConsumerWidget {
  const PricingRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PricingRule>> source = ref.watch(
      pricingRulesProvider,
    );
    final List<PricingRule> rules = ref.watch(activePricingRulesProvider);

    return AppAddFabScaffold(
      appBar: SdAppBarV3(title: context.l10n.pricingRulesTitle),
      addLabel: context.l10n.pricingRuleAdd,
      onAdd: () => context.push(AppRoutes.addPricingRule),
      body: switch (source) {
        AsyncLoading<List<PricingRule>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        _ when rules.isEmpty => SdEmptyStateV3(
          icon: AppIconConstant.sell,
          title: context.l10n.pricingRulesEmptyTitle,
          message: context.l10n.pricingRulesEmptyBody,
          action: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.pricingRuleAdd,
            onPressed: () => context.push(AppRoutes.addPricingRule),
          ),
        ),
        _ => ListView(
          padding: AppAddFabScaffold.listPadding(context),
          children: <Widget>[
            SizedBox(height: SdContentPaddingV3.topGap),
            AppListCard(
              children: <Widget>[
                for (final PricingRule rule in rules)
                  AppListRow(
                    title: rule.name,
                    subtitle: PricingRuleLabel.summary(context, rule),
                    icon: AppIconConstant.sell,
                    onTap: () => context.push(AppRoutes.pricingRule(rule.id)),
                  ),
              ],
            ),
          ],
        ),
      },
    );
  }
}
