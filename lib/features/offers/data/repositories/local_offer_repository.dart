import '../../../../core/constants/guest_constant.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/local/local_collection.dart';
import '../../../../core/local/local_database.dart';
import '../../../../core/local/local_table.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';
import '../dtos/offer_dto.dart';

/// Offers, before anyone signs in (`docs/rules/GUEST_MODE.md`).
class LocalOfferRepository implements OfferRepository {
  LocalOfferRepository(LocalDatabase db, {required String currency})
    : _collection = LocalCollection<Offer>(
        table: LocalTable(db, db.localOffers),
        fromMap: (String id, Map<String, Object?> data) =>
            OfferDto.fromMap(id, data, fallbackCurrency: currency),
        toMap: (Offer offer) =>
            OfferDto.toMap(offer, createdBy: GuestConstant.uid),
        idOf: (Offer offer) => offer.id,
        createdAtOf: (Offer offer) => offer.createdAt,
        logTag: LogTagConstant.offer,
        label: 'offer',
      );

  final LocalCollection<Offer> _collection;

  @override
  Stream<List<Offer>> watchOffers() => _collection.watchAll();

  @override
  Future<void> save(Offer offer) => _collection.save(offer);
}
