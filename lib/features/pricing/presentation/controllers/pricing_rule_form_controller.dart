import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/pricing_rule.dart';

/// Saving and deleting a pricing rule. True while a write is in flight.
class PricingRuleFormController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Writes [draft], keeping the record's own id and creation date when it
  /// already exists. Returns the id, or null when nothing was written.
  Future<String?> submit(PricingRule draft) async {
    if (draft.name.trim().isEmpty || draft.multiplier <= 0 || state) {
      return null;
    }

    state = true;
    SdLogger.action(
      LogTagConstant.pricing,
      'Pricing rule form submitted',
      <String, Object>{
        'ruleId': draft.id,
        'scope': draft.scope.name,
        'multiplier': draft.multiplier,
        'rounding': draft.rounding.name,
      },
    );

    try {
      await ref.read(pricingRuleRepositoryProvider).save(draft);

      return draft.id;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.pricing,
        'Pricing rule form failed to save',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'ruleId': draft.id},
      );
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> delete(String ruleId) async {
    SdLogger.action(
      LogTagConstant.pricing,
      'Delete pricing rule',
      <String, Object>{'ruleId': ruleId},
    );

    try {
      await ref.read(pricingRuleRepositoryProvider).delete(ruleId);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.pricing,
        'Failed to delete pricing rule',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'ruleId': ruleId},
      );
      rethrow;
    }
  }
}

final NotifierProvider<PricingRuleFormController, bool>
pricingRuleFormControllerProvider =
    NotifierProvider<PricingRuleFormController, bool>(
      PricingRuleFormController.new,
    );
