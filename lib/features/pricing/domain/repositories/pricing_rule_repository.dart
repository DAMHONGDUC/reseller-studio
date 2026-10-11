import '../entities/pricing_rule.dart';

/// Reading and writing a business's pricing rules.
abstract interface class PricingRuleRepository {
  /// Every rule, soft-deleted ones included — a price history row may still
  /// name one.
  Stream<List<PricingRule>> watchRules();

  Future<void> save(PricingRule rule);

  /// Soft delete (hard rule 15): price history points at rules.
  Future<void> delete(String ruleId);
}
