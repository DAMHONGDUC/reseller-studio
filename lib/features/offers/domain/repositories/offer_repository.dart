import '../entities/offer.dart';

/// Reading and writing offers.
///
/// See `ItemRepository` for why these are streams and why failures never
/// cross this line as Firebase types.
abstract interface class OfferRepository {
  /// Every offer, newest first. The Offers screen's four tabs are a fold over
  /// this one stream rather than four queries.
  Stream<List<Offer>> watchOffers();

  Future<void> save(Offer offer);
}
