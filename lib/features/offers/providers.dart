/// Riverpod wiring for `offers`.
///
/// Offers live under Orders rather than as their own bottom tab (hard rule
/// 13): an offer is the step before a sale, and a seller works them in the
/// same sitting as the parcels.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../mock_data/providers.dart';
import '../orders/domain/enums/order_status.dart';
import 'domain/entities/offer.dart';

/// The tabs across the top of Offers (plan §8).
enum OfferFilter {
  pending,
  accepted,
  declined,
  expired;

  String get label => switch (this) {
    OfferFilter.pending => 'Pending',
    OfferFilter.accepted => 'Accepted',
    OfferFilter.declined => 'Declined',
    OfferFilter.expired => 'Expired',
  };

  /// Whether [offer] belongs under this tab, as of [now].
  ///
  /// **Expiry is decided by the clock, not by the stored status** (hard rule
  /// 3): a pending offer whose window has closed belongs under Expired
  /// immediately, not after some job runs. Otherwise the app shows an Accept
  /// button for something the platform has already closed.
  bool matches(Offer offer, DateTime now) {
    if (offer.hasExpired(now)) return this == OfferFilter.expired;

    return switch (this) {
      OfferFilter.pending => offer.status == OfferStatus.pending,
      OfferFilter.accepted => offer.status == OfferStatus.accepted,
      OfferFilter.declined =>
        offer.status == OfferStatus.declined ||
            offer.status == OfferStatus.countered,
      OfferFilter.expired => false,
    };
  }
}

final StreamProvider<List<Offer>> offersProvider = StreamProvider<List<Offer>>(
  (Ref ref) => ref.watch(offerRepositoryProvider).watchOffers(),
);

class OfferFilterController extends Notifier<OfferFilter> {
  @override
  OfferFilter build() => OfferFilter.pending;

  void select(OfferFilter filter) => state = filter;
}

final NotifierProvider<OfferFilterController, OfferFilter> offerFilterProvider =
    NotifierProvider<OfferFilterController, OfferFilter>(
      OfferFilterController.new,
    );

final Provider<Map<OfferFilter, int>> offerCountsProvider =
    Provider<Map<OfferFilter, int>>((Ref ref) {
      final List<Offer> offers =
          ref.watch(offersProvider).value ?? const <Offer>[];
      final DateTime now = DateTime.now();

      return <OfferFilter, int>{
        for (final OfferFilter filter in OfferFilter.values)
          filter: offers
              .where((Offer offer) => filter.matches(offer, now))
              .length,
      };
    });

final Provider<List<Offer>> visibleOffersProvider = Provider<List<Offer>>((
  Ref ref,
) {
  final List<Offer> offers =
      ref.watch(offersProvider).value ?? const <Offer>[];
  final OfferFilter filter = ref.watch(offerFilterProvider);
  final DateTime now = DateTime.now();

  return offers.where((Offer offer) => filter.matches(offer, now)).toList();
});

/// Offers still waiting on the seller, soonest to lapse first.
///
/// What Home's Needs Attention counts. Sorted by deadline rather than by when
/// the offer arrived: the one about to close is the one that costs money to
/// ignore, whatever order they came in.
final Provider<List<Offer>> pendingOffersProvider = Provider<List<Offer>>((
  Ref ref,
) {
  final List<Offer> offers =
      ref.watch(offersProvider).value ?? const <Offer>[];
  final DateTime now = DateTime.now();

  final List<Offer> pending =
      offers
          .where((Offer offer) => offer.needsAction && !offer.hasExpired(now))
          .toList()
        ..sort((Offer a, Offer b) {
          final DateTime? left = a.expiresAt;
          final DateTime? right = b.expiresAt;

          // An offer with no deadline is real work, but nothing external is
          // counting down on it, so it sorts last.
          if (left == null && right == null) {
            return b.createdAt.compareTo(a.createdAt);
          }
          if (left == null) return 1;
          if (right == null) return -1;

          return left.compareTo(right);
        });

  return pending;
});
