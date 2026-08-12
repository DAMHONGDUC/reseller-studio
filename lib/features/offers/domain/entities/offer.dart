import '../../../../core/money/money.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../../orders/domain/enums/order_status.dart';

/// A buyer asking to pay less than the asking price (plan §8).
///
/// **Offers live under Orders, not as their own tab** (hard rule 13): an offer
/// is the step before a sale, and a seller works them in the same sitting as
/// the parcels.
///
/// [expiresAt] is what makes this urgent rather than a message. A pending
/// offer with hours left is the single most time-sensitive thing in the app —
/// everything else waits.
class Offer {
  const Offer({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.marketplace,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.listingId,
    this.expiresAt,
    this.buyerName,
    this.message,
    this.counterAmount,
    this.respondedAt,
  });

  final String id;
  final String itemId;

  /// Denormalised at creation, so the list renders without a read per row and
  /// an offer still reads correctly after the item is archived.
  final String itemTitle;

  final Marketplace marketplace;

  /// What the buyer offered.
  final Money amount;

  final OfferStatus status;
  final DateTime createdAt;
  final String? listingId;

  /// When the platform stops accepting a response. Null for an offer made
  /// outside an integration — a message on a marketplace with no timer.
  final DateTime? expiresAt;

  final String? buyerName;
  final String? message;

  /// What the seller came back with, when [status] is `countered`.
  final Money? counterAmount;

  final DateTime? respondedAt;

  /// Whether this offer still needs the seller to do something.
  bool get needsAction => status == OfferStatus.pending;

  /// True once the window has closed, whatever the stored status says.
  ///
  /// **Derived rather than stored** (hard rule 3): an offer does not become
  /// expired because a job ran, it becomes expired because time passed, and a
  /// seller must not be shown an Accept button for something the platform has
  /// already closed.
  bool hasExpired(DateTime now) {
    final DateTime? deadline = expiresAt;

    if (status != OfferStatus.pending || deadline == null) {
      return status == OfferStatus.expired;
    }

    return now.isAfter(deadline);
  }

  /// How far below the asking price the buyer came, as a fraction of it.
  ///
  /// Null when the item has no asking price — there is nothing to be below.
  /// It is the number that decides the answer, which is why the screen shows
  /// it rather than making the seller do the arithmetic.
  double? discountFrom(Money? askingPrice) {
    final Money? asking = askingPrice;

    if (asking == null || asking.isZero) return null;

    return (asking - amount).ratioOf(asking);
  }

  Offer copyWith({
    OfferStatus? status,
    Money? counterAmount,
    DateTime? respondedAt,
  }) => Offer(
    id: id,
    itemId: itemId,
    itemTitle: itemTitle,
    marketplace: marketplace,
    amount: amount,
    status: status ?? this.status,
    createdAt: createdAt,
    listingId: listingId,
    expiresAt: expiresAt,
    buyerName: buyerName,
    message: message,
    counterAmount: counterAmount ?? this.counterAmount,
    respondedAt: respondedAt ?? this.respondedAt,
  );
}
