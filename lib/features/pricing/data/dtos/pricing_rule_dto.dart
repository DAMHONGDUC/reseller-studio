import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/firestore/workspace_collections.dart';
import '../../domain/entities/pricing_rule.dart';
import '../../domain/enums/price_rounding.dart';
import '../../domain/enums/pricing_rule_scope.dart';

/// How a [PricingRule] is stored, in `pricing_rules`.
///
/// Both amounts share one `currency` field: a rule speaks one currency, and
/// the calculator refuses to apply it to a cost in another (hard rule 4).
final class PricingRuleDto {
  static PricingRule toEntity(
    DocumentSnapshot<Map<String, Object?>> doc, {
    required String fallbackCurrency,
  }) => fromMap(
    WorkspaceTable.localId(doc.id),
    doc.data() ?? <String, Object?>{},
    fallbackCurrency: fallbackCurrency,
  );

  /// The map boundary both stores share (`docs/rules/GUEST_MODE.md`).
  static PricingRule fromMap(
    String id,
    Map<String, Object?> data, {
    required String fallbackCurrency,
  }) {
    final String currency =
        FirestoreMapper.stringOrNull(data['currency']) ?? fallbackCurrency;

    return PricingRule(
      id: id,
      name: FirestoreMapper.stringOrNull(data['name']) ?? '',
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      scope:
          FirestoreMapper.enumOrNull(PricingRuleScope.values, data['scope']) ??
          PricingRuleScope.all,
      scopeId: FirestoreMapper.stringOrNull(data['scopeId']),
      multiplier: FirestoreMapper.doubleOrNull(data['multiplier']) ?? 1,
      fixedAdd: FirestoreMapper.moneyOrNull(data['fixedAddMinor'], currency),
      rounding:
          FirestoreMapper.enumOrNull(PriceRounding.values, data['rounding']) ??
          PriceRounding.none,
      minProfit: FirestoreMapper.moneyOrNull(data['minProfitMinor'], currency),
      minSupplierStock: FirestoreMapper.intOrNull(data['minSupplierStock']),
      staleDays: FirestoreMapper.intOrNull(data['staleDays']),
      staleDropPercent: FirestoreMapper.doubleOrNull(data['staleDropPercent']),
      applyOnSupplierChange: FirestoreMapper.boolOr(
        data['applyOnSupplierChange'],
        fallback: false,
      ),
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  static Map<String, Object?> toMap(
    PricingRule rule, {
    required String currency,
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'name': rule.name,
    'scope': rule.scope.name,
    'scopeId': rule.scopeId,
    'multiplier': rule.multiplier,
    'currency': rule.fixedAdd?.currency ?? rule.minProfit?.currency ?? currency,
    'fixedAddMinor': FirestoreMapper.minorOrNull(rule.fixedAdd),
    'rounding': rule.rounding.name,
    'minProfitMinor': FirestoreMapper.minorOrNull(rule.minProfit),
    'minSupplierStock': rule.minSupplierStock,
    'staleDays': rule.staleDays,
    'staleDropPercent': rule.staleDropPercent,
    'applyOnSupplierChange': rule.applyOnSupplierChange,
    'deletedAt': rule.deletedAt == null
        ? null
        : Timestamp.fromDate(rule.deletedAt!),
    'createdAt': Timestamp.fromDate(rule.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });
}
