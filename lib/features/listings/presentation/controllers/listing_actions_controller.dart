import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../mock_data/providers.dart';
import '../../domain/entities/listing.dart';
import '../../domain/enums/listing_status.dart';

/// Everything a seller does to listings once they exist: cut the price, pause
/// them, end them — one at a time or forty at once (plan §12).
///
/// **The bulk path is the point** (hard rule 16). `saveAll` batches the write,
/// so a screenful of stale listings is one round trip rather than forty, and
/// bulk price update is one of the three things plan §12 names.
///
/// **Nothing here talks to a marketplace.** No integration exists yet (hard
/// rule 10 keeps every token server-side), so these change what Seller OS
/// records. The day a platform is connected, the sync is a Cloud Function
/// reading the same documents — not a call added to this class.
class ListingActionsController extends Notifier<bool> {
  /// True while a write is in flight, so a bar can disable its buttons.
  @override
  bool build() => false;

  /// Bulk price update — plan §12, and the reason a seller keeps a
  /// spreadsheet open next to an app that cannot do it.
  Future<void> reprice(List<Listing> listings, Money price) => _bulk(
    'Reprice listings',
    listings,
    <String, Object>{'priceMinor': price.minor},
    (Listing listing) => listing.copyWith(price: price),
  );

  /// Move listings to a status.
  ///
  /// **`sold` is not reachable from here.** A listing sells because an order
  /// exists; letting a bulk control mark one sold would create a sale with no
  /// order behind it, and every profit figure is derived from orders.
  Future<void> setStatus(List<Listing> listings, ListingStatus status) {
    if (status == ListingStatus.sold) return Future<void>.value();

    return _bulk(
      'Set listing status',
      listings,
      <String, Object>{'status': status.name},
      (Listing listing) => listing.copyWith(
        status: status,
        // Ending is when a listing stopped being live. Anything else leaves
        // the date alone — a paused listing has not ended.
        endedAt: status == ListingStatus.ended
            ? DateTime.now()
            : listing.endedAt,
      ),
    );
  }

  /// The one write path every bulk edit goes through.
  ///
  /// [describe] is what the log line says; [data] is what it says *about* the
  /// change, so a report six weeks later names the price rather than only the
  /// count.
  Future<void> _bulk(
    String describe,
    List<Listing> listings,
    Map<String, Object> data,
    Listing Function(Listing) change,
  ) async {
    if (listings.isEmpty) return;

    SdLogger.action(LogTagConstant.listing, describe, <String, Object>{
      'count': listings.length,
      ...data,
    });
    AppAnalytics.instance.bulkAction(action: describe, count: listings.length);

    state = true;

    try {
      await ref
          .read(listingRepositoryProvider)
          .saveAll(listings.map(change).toList());
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.listing,
        'Failed to $describe',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'count': listings.length, ...data},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<ListingActionsController, bool>
listingActionsControllerProvider =
    NotifierProvider<ListingActionsController, bool>(
      ListingActionsController.new,
    );
