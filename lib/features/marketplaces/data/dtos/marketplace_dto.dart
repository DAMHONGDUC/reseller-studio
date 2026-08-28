import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../domain/entities/marketplace.dart';

/// How a [Marketplace] is stored.
final class MarketplaceDto {
  static Marketplace toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};

    return Marketplace(
      id: doc.id,
      name: FirestoreMapper.stringOrNull(data['name']) ?? '',
      // Zero rather than a guess when the field is missing or malformed: an
      // invented cut is a wrong profit figure on every order, whereas a
      // missing one is visibly zero and gets corrected.
      feeRate: (data['feeRate'] as num?)?.toDouble() ?? 0,
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  static Map<String, Object?> toMap(
    Marketplace marketplace, {
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'name': marketplace.name,
    'feeRate': marketplace.feeRate,
    'deletedAt': marketplace.deletedAt == null
        ? null
        : Timestamp.fromDate(marketplace.deletedAt!),
    'createdAt': Timestamp.fromDate(marketplace.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });
}
