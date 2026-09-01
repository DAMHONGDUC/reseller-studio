/// Riverpod wiring for `listings`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/state/selection_controller.dart';
import '../marketplaces/domain/services/marketplace_order.dart';
import '../mock_data/providers.dart';
import '../workspace/providers.dart';
import 'domain/entities/listing.dart';

final StreamProvider<List<Listing>> listingsProvider =
    StreamProvider<List<Listing>>((Ref ref) {
      return WorkspaceGuard.listOrEmpty<Listing>(
        ref,
        () => ref.watch(listingRepositoryProvider).watchListings(),
      );
    });

/// Every marketplace one item is live on — the item detail's Listings block
/// and the cross-listing screen.
///
/// **Ordered here, so no screen has to think about it.** The query answers
/// "which listings", not "in what order", and two screens reading the same
/// item were drawing its marketplaces in two orders (`MarketplaceOrder`).
// See `itemProvider` for why the type is inferred rather than written.
// ignore: type_annotate_public_apis
final listingsForItemProvider = StreamProvider.family<List<Listing>, String>((
  Ref ref,
  String itemId,
) {
  return WorkspaceGuard.listOrEmpty<Listing>(
    ref,
    () => ref
        .watch(listingRepositoryProvider)
        .watchListingsForItem(itemId)
        .map(
          (List<Listing> listings) => MarketplaceOrder.sort(
            listings,
            (Listing listing) => listing.marketplace,
          ),
        ),
  );
});

/// Which listings are ticked for a bulk action.
///
/// The behaviour is `SelectionController` in `core/state/`; Inventory ticks
/// rows the same way. What is here is the listing half.
class ListingSelectionController extends SelectionController {}

final NotifierProvider<ListingSelectionController, Set<String>>
listingSelectionProvider =
    NotifierProvider<ListingSelectionController, Set<String>>(
      ListingSelectionController.new,
    );

/// The selected listings themselves, resolved from the live list.
///
/// Derived rather than copied at tick time: a listing a teammate repriced
/// while the selection is open must reach the action with its new values.
final Provider<List<Listing>> selectedListingsProvider =
    Provider<List<Listing>>((Ref ref) {
      final Set<String> ids = ref.watch(listingSelectionProvider);

      if (ids.isEmpty) return const <Listing>[];

      final List<Listing> listings =
          ref.watch(listingsProvider).value ?? const <Listing>[];

      return listings
          .where((Listing listing) => ids.contains(listing.id))
          .toList();
    });
