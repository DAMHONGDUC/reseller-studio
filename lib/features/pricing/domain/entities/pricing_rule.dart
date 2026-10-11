import '../../../../core/money/money.dart';
import '../enums/price_rounding.dart';
import '../enums/pricing_rule_scope.dart';

/// How a business turns a cost into an asking price (plan §15 "pricing
/// rules", `docs/DROPSHIPPING_PLAN.md`).
///
/// The rule is configuration and the price is derived from it at the moment a
/// seller applies it. Nothing it produces is stored as a figure about a sale
/// (hard rule 3): the listing's price is what the seller asked, and the
/// expected profit beside it is recomputed every time it is shown.
class PricingRule {
  const PricingRule({
    required this.id,
    required this.name,
    required this.createdAt,
    this.scope = PricingRuleScope.all,
    this.scopeId,
    this.multiplier = 1,
    this.fixedAdd,
    this.rounding = PriceRounding.none,
    this.minProfit,
    this.minSupplierStock,
    this.staleDays,
    this.staleDropPercent,
    this.applyOnSupplierChange = false,
    this.deletedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final PricingRuleScope scope;

  /// The marketplace record or category [scope] names; null for
  /// [PricingRuleScope.all].
  final String? scopeId;

  /// What the cost is multiplied by — 2 doubles it.
  final double multiplier;

  /// Added after the multiplier; null adds nothing.
  final Money? fixedAdd;

  final PriceRounding rounding;

  /// The least the seller will clear after the planning fee; the floor no
  /// price this rule gives may go under. Null means break-even.
  final Money? minProfit;

  /// Supplier stock under which a dropship listing is taken to zero.
  final int? minSupplierStock;

  /// Days unsold before [staleDropPercent] lowers the price.
  final int? staleDays;

  /// How much a stale listing is lowered by, as a fraction — 0.05 is 5%.
  final double? staleDropPercent;

  /// Whether a supplier price change re-applies this rule on its own.
  final bool applyOnSupplierChange;

  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// Whether stale repricing is switched on for this rule.
  bool get dropsWhenStale {
    final int? days = staleDays;
    final double? percent = staleDropPercent;

    return days != null && days > 0 && percent != null && percent > 0;
  }

  PricingRule copyWith({
    String? name,
    PricingRuleScope? scope,
    String? scopeId,
    double? multiplier,
    Money? fixedAdd,
    PriceRounding? rounding,
    Money? minProfit,
    int? minSupplierStock,
    int? staleDays,
    double? staleDropPercent,
    bool? applyOnSupplierChange,
    DateTime? deletedAt,
  }) => PricingRule(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt,
    scope: scope ?? this.scope,
    scopeId: scopeId ?? this.scopeId,
    multiplier: multiplier ?? this.multiplier,
    fixedAdd: fixedAdd ?? this.fixedAdd,
    rounding: rounding ?? this.rounding,
    minProfit: minProfit ?? this.minProfit,
    minSupplierStock: minSupplierStock ?? this.minSupplierStock,
    staleDays: staleDays ?? this.staleDays,
    staleDropPercent: staleDropPercent ?? this.staleDropPercent,
    applyOnSupplierChange: applyOnSupplierChange ?? this.applyOnSupplierChange,
    deletedAt: deletedAt ?? this.deletedAt,
  );
}
