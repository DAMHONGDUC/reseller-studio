import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/firestore/firestore_stream.dart';
import '../../../../core/firestore/workspace_context.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';
import '../dtos/offer_dto.dart';

/// Offers, in Firestore.
class FirestoreOfferRepository implements OfferRepository {
  const FirestoreOfferRepository(this._context);

  final WorkspaceContext _context;

  @override
  Stream<List<Offer>> watchOffers() => FirestoreStream.collection(
    _context.collections.offers.query.orderBy('createdAt', descending: true),
    _toEntity,
    operation: 'load offers',
  );

  @override
  Future<void> save(Offer offer) => FailureMapper.guard('save offer', () async {
    await _context.collections.offers
        .doc(offer.id)
        .set(
          OfferDto.toMap(offer, createdBy: _context.uid),
          SetOptions(merge: true),
        );

    SdLogger.info(LogTagConstant.offer, 'Offer saved', <String, Object>{
      'offerId': offer.id,
      'status': offer.status.name,
    });
  });

  Offer _toEntity(DocumentSnapshot<Map<String, Object?>> doc) =>
      OfferDto.toEntity(doc, fallbackCurrency: _context.currency);
}
