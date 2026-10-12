import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../workspace/providers.dart';
import 'domain/entities/pricing_rule.dart';

/// Every pricing rule, deleted ones included, oldest first.
final StreamProvider<List<PricingRule>> pricingRulesProvider =
    StreamProvider<List<PricingRule>>((Ref ref) {
      return WorkspaceGuard.listOrEmpty<PricingRule>(
        ref,
        () => ref.watch(pricingRuleRepositoryProvider).watchRules(),
      );
    });

/// The rules a seller can still apply, oldest first.
final Provider<List<PricingRule>> activePricingRulesProvider =
    Provider<List<PricingRule>>((Ref ref) {
      return <PricingRule>[
        for (final PricingRule rule
            in ref.watch(pricingRulesProvider).value ?? const <PricingRule>[])
          if (!rule.isDeleted) rule,
      ]..sort(
        (PricingRule a, PricingRule b) => a.createdAt.compareTo(b.createdAt),
      );
    });
