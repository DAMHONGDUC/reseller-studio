import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_mapper.dart';
import '../../../../core/theme/app_tag_hue.dart';
import '../../domain/entities/marketplace.dart';

/// How a [Marketplace] is stored.
final class MarketplaceDto {
  static Marketplace toEntity(DocumentSnapshot<Map<String, Object?>> doc) {
    final Map<String, Object?> data = doc.data() ?? <String, Object?>{};

    return Marketplace(
      id: doc.id,
      name: FirestoreMapper.stringOrNull(data['name']) ?? '',
      createdAt: FirestoreMapper.dateOr(data['createdAt'], DateTime.now()),
      // Stored by name, never by index: a reordered enum would otherwise
      // repaint every marketplace in the business.
      hue: AppTagHue.fromName(FirestoreMapper.stringOrNull(data['hue'])),
      deletedAt: FirestoreMapper.dateOrNull(data['deletedAt']),
    );
  }

  static Map<String, Object?> toMap(
    Marketplace marketplace, {
    required String createdBy,
  }) => FirestoreMapper.pruned(<String, Object?>{
    'name': marketplace.name,
    'hue': marketplace.hue.name,
    'deletedAt': marketplace.deletedAt == null
        ? null
        : Timestamp.fromDate(marketplace.deletedAt!),
    'createdAt': Timestamp.fromDate(marketplace.createdAt),
    'updatedAt': FirestoreMapper.serverTimestamp,
    'createdBy': createdBy,
  });
}
