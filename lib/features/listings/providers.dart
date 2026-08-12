/// Riverpod wiring for `listings`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../mock_data/providers.dart';
import 'domain/entities/listing.dart';

final StreamProvider<List<Listing>> listingsProvider =
    StreamProvider<List<Listing>>((Ref ref) {
      return ref.watch(listingRepositoryProvider).watchListings();
    });

/// Every marketplace one item is live on — the item detail's Listings block
/// and the cross-listing screen.
// See `itemProvider` for why the type is inferred rather than written.
// ignore: type_annotate_public_apis
final listingsForItemProvider = StreamProvider.family<List<Listing>, String>((
  Ref ref,
  String itemId,
) {
  return ref.watch(listingRepositoryProvider).watchListingsForItem(itemId);
});
