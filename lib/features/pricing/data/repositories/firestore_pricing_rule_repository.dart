import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/entities/pricing_rule.dart';
import '../../domain/repositories/pricing_rule_repository.dart';
import '../dtos/pricing_rule_dto.dart';

/// Pricing rules, in Firestore.
class FirestorePricingRuleRepository implements PricingRuleRepository {
  const FirestorePricingRuleRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<PricingRule>> watchRules() => FirestoreStream.collection(
    _context.collections.pricingRules.query.orderBy('createdAt'),
    (DocumentSnapshot<Map<String, Object?>> doc) =>
        PricingRuleDto.toEntity(doc, fallbackCurrency: _context.currency),
    operation: 'load pricing rules',
  );

  @override
  Future<void> save(PricingRule rule) =>
      FailureMapper.guard('save pricing rule', () async {
        await _context.collections.pricingRules
            .doc(rule.id)
            .set(
              PricingRuleDto.toMap(
                rule,
                currency: _context.currency,
                createdBy: _context.uid,
              ),
              SetOptions(merge: true),
            );
        SdLogger.info(
          LogTagConstant.pricing,
          'Pricing rule saved',
          <String, Object>{'ruleId': rule.id, 'scope': rule.scope.name},
        );
      });

  @override
  Future<void> delete(String ruleId) => FailureMapper.guard(
    'delete pricing rule',
    () async {
      await _context.collections.pricingRules.doc(ruleId).set(<String, Object?>{
        'deletedAt': Timestamp.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      SdLogger.info(
        LogTagConstant.pricing,
        'Pricing rule deleted',
        <String, Object>{'ruleId': ruleId},
      );
    },
  );
}
