import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/pricing_rule.dart';
import '../../domain/repositories/pricing_rule_repository.dart';
import '../dtos/pricing_rule_dto.dart';

/// Pricing rules, before anyone signs in (`docs/rules/GUEST_MODE.md`).
class LocalPricingRuleRepository implements PricingRuleRepository {
  LocalPricingRuleRepository(LocalDatabase db, {required String currency})
    : _collection = LocalCollection<PricingRule>(
        table: LocalTable(db, db.localPricingRules),
        fromMap: (String id, Map<String, Object?> data) =>
            PricingRuleDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (PricingRule rule) => PricingRuleDto.toMap(
          rule,
          currency: currency,
          createdBy: GuestConstant.uid,
        ),
        idOf: (PricingRule rule) => rule.id,
        createdAtOf: (PricingRule rule) => rule.createdAt,
        logTag: LogTagConstant.pricing,
        label: 'pricing rule',
      );

  final LocalCollection<PricingRule> _collection;

  @override
  Stream<List<PricingRule>> watchRules() => _collection.watchAll();

  @override
  Future<void> save(PricingRule rule) => _collection.save(rule);

  @override
  Future<void> delete(String ruleId) => _collection.softDelete(ruleId);
}
