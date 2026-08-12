import '../../../../core/money/money.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../enums/listing_status.dart';

/// One item, live on one marketplace.
///
/// **One item has many listings** — that is what cross-listing means (plan
/// §13), and it is why this is its own entity rather than fields on `Item`.
/// The same jacket can be on eBay at £45 and Depop at £40 with different
/// titles, and when it sells on one the others must come down.
class Listing {
  const Listing({
    required this.id,
    required this.itemId,
    required this.marketplace,
    required this.title,
    required this.price,
    required this.status,
    required this.createdAt,
    this.description,
    this.photoUrls = const <String>[],
    this.externalListingId,
    this.externalUrl,
    this.publishedAt,
    this.endedAt,
    this.viewCount,
    this.watcherCount,
    this.lastError,
  });

  final String id;
  final String itemId;
  final Marketplace marketplace;

  /// Per-marketplace, because the platforms reward different titles and
  /// enforce different lengths. Defaults to the item's title; diverges the
  /// moment a seller optimises one.
  final String title;

  final Money price;
  final ListingStatus status;
  final DateTime createdAt;
  final String? description;
  final List<String> photoUrls;

  /// How the sync layer matches a remote listing back to this one. Null until
  /// a publish succeeds — which is also how a draft is told from a listing
  /// that failed to publish.
  final String? externalListingId;
  final String? externalUrl;

  final DateTime? publishedAt;
  final DateTime? endedAt;

  /// Platform engagement, when the integration reports it. Null is "not
  /// known", not zero — a listing with no data is not a listing nobody
  /// looked at.
  final int? viewCount;
  final int? watcherCount;

  /// Why the platform rejected it, when [status] is `error`. Shown to the
  /// seller because it is *their* action item — this is the one place a
  /// platform's own message is surfaced, and it is not a technical error in
  /// the sense hard rule 6 forbids.
  final String? lastError;

  /// Days live, or null if never published.
  int? daysLive(DateTime now) {
    final DateTime? published = publishedAt;

    if (published == null) return null;

    return now.difference(published).inDays;
  }
}
