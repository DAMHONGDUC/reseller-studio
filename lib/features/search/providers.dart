/// Riverpod wiring for global search (plan §21).
///
/// **It searches what is already in memory rather than querying.** Every
/// collection this app shows is already open as a live stream for the tab that
/// displays it, so a search that went back to Firestore would pay for data it
/// already has and would need a composite index per field. The trade is that
/// it cannot find something the client has not loaded — which, for a
/// reseller's workspace, it always has.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../inventory/domain/entities/item.dart';
import '../inventory/providers.dart';
import '../listings/domain/entities/listing.dart';
import '../listings/providers.dart';
import '../orders/domain/entities/order.dart';
import '../orders/providers.dart';
import '../sourcing/domain/entities/source.dart';
import '../sourcing/providers.dart';

/// What a hit points at, so the screen knows where to send the tap.
enum SearchHitKind { item, order, listing, source }

/// One row of results.
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.title,
    this.detail,
    this.status,
  });

  final SearchHitKind kind;

  /// The id to navigate with. For a listing this is its **item's** id — a
  /// listing has no screen of its own, and the item is what the seller wants
  /// when they search a marketplace title.
  final String id;

  final String title;

  /// The part of the second line that is already words — a SKU, a marketplace
  /// name. Never a status: see [status].
  final String? detail;

  /// The record's status, still an enum.
  ///
  /// **Deliberately not turned into a string here.** A provider has no
  /// `BuildContext`, so a status resolved in this file could only be
  /// `status.name` — which is a Dart identifier, and putting `partiallyRefunded`
  /// in front of a seller is both hard rule 7 and simply wrong. `SearchSubtitle`
  /// does it where the context exists.
  final Enum? status;
}

/// What is typed in the search box.
class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;

  void clear() => state = '';
}

final NotifierProvider<SearchQueryController, String> searchQueryProvider =
    NotifierProvider<SearchQueryController, String>(SearchQueryController.new);

/// Everything matching the query, across items, orders, listings and sources.
///
/// The fields searched are the ones a seller has to hand when they are looking
/// for something (plan §21): a title, a SKU, a barcode, an order id, a
/// tracking number. **Notes and descriptions are deliberately not searched** —
/// they are long, and matching them makes the results look random to someone
/// who typed a SKU.
final Provider<List<SearchHit>>
searchResultsProvider = Provider<List<SearchHit>>((Ref ref) {
  final String query = ref.watch(searchQueryProvider).trim().toLowerCase();

  if (query.length < SearchConstant.minimumQueryLength) {
    return const <SearchHit>[];
  }

  final List<SearchHit> hits = <SearchHit>[];

  for (final Item item in ref.watch(itemsProvider).value ?? const <Item>[]) {
    if (SearchConstant.matches(query, <String?>[
      item.title,
      item.sku,
      item.barcode,
    ])) {
      hits.add(
        SearchHit(
          kind: SearchHitKind.item,
          id: item.id,
          title: item.title,
          status: item.status,
          detail: item.sku,
        ),
      );
    }
  }

  for (final Order order
      in ref.watch(ordersProvider).value ?? const <Order>[]) {
    if (SearchConstant.matches(query, <String?>[
      order.externalOrderId,
      order.trackingNumber,
      order.buyerName,
      ...order.lines.map((OrderLine line) => line.title),
    ])) {
      hits.add(
        SearchHit(
          kind: SearchHitKind.order,
          id: order.id,
          title: order.lines.isEmpty
              ? order.marketplace.displayName
              : order.lines.first.title,
          status: order.status,
          detail: order.marketplace.displayName,
        ),
      );
    }
  }

  for (final Listing listing
      in ref.watch(listingsProvider).value ?? const <Listing>[]) {
    if (SearchConstant.matches(query, <String?>[
      listing.title,
      listing.externalListingId,
    ])) {
      hits.add(
        SearchHit(
          kind: SearchHitKind.listing,
          id: listing.itemId,
          title: listing.title,
          status: listing.status,
          detail: listing.marketplace.displayName,
        ),
      );
    }
  }

  for (final Source source
      in ref.watch(sourcesProvider).value ?? const <Source>[]) {
    if (SearchConstant.matches(query, <String?>[source.name, source.address])) {
      hits.add(
        SearchHit(
          kind: SearchHitKind.source,
          id: source.id,
          title: source.name,
          detail: source.address,
        ),
      );
    }
  }

  return hits;
});

/// The matching rule, in one place so every collection is searched the same
/// way.
final class SearchConstant {
  /// Below this a query matches most of the workspace, and the screen is a
  /// wall of rows rather than an answer.
  static const int minimumQueryLength = 2;

  /// True when any field contains the query. Case-insensitive, substring —
  /// a seller who remembers the middle of a title should find it.
  static bool matches(String query, List<String?> fields) {
    for (final String? field in fields) {
      if (field != null && field.toLowerCase().contains(query)) return true;
    }

    return false;
  }
}
