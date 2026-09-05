import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme/app_tag_hue.dart';
import '../listings/domain/entities/listing.dart';
import '../listings/domain/services/listing_marketplaces.dart';
import '../listings/providers.dart';
import '../mock_data/providers.dart';
import '../workspace/providers.dart';
import 'domain/entities/marketplace.dart';
import 'domain/services/marketplace_matching.dart';
import 'marketplace_constant.dart';

/// The normal marketplace records created for every new business.
///
/// Exposed here because another feature may import this feature's providers,
/// while the default definition itself remains owned by Marketplaces.
final Provider<List<Marketplace>> defaultMarketplacesProvider =
    Provider<List<Marketplace>>((Ref ref) {
      final DateTime createdAt = DateTime.now();

      return <Marketplace>[
        for (final (int index, MarketplaceSeed seed)
            in MarketplaceConstant.defaults.indexed)
          Marketplace(
            id: seed.id,
            name: seed.name,
            // A millisecond apart, never one instant: the list is read back
            // ordered by `createdAt`, and five identical stamps leave the tie
            // to the document id — the seeded order in mock data and
            // alphabetical order in Firestore, for the same five rows.
            createdAt: createdAt.add(Duration(milliseconds: index)),
            hue: seed.hue,
          ),
      ];
    });

/// Every marketplace this business has, deleted ones included.
///
/// The deleted ones stay in the stream because a past order still names one,
/// and a row reading its raw id is worse than a row reading "Depop" with the
/// platform no longer offered as a destination (hard rule 15).
final StreamProvider<List<Marketplace>> marketplacesProvider =
    StreamProvider<List<Marketplace>>((Ref ref) {
      return WorkspaceGuard.listOrEmpty<Marketplace>(
        ref,
        () => ref.watch(marketplaceRepositoryProvider).watchMarketplaces(),
      );
    });

/// The ones a seller may still list on — every picker reads this.
final Provider<List<Marketplace>> activeMarketplacesProvider =
    Provider<List<Marketplace>>((Ref ref) {
      return <Marketplace>[
        for (final Marketplace marketplace
            in ref.watch(marketplacesProvider).value ?? const <Marketplace>[])
          if (!marketplace.isDeleted) marketplace,
      ];
    });

/// The ones an item is actually on, for a picker that is about that item.
///
/// **Falls back to every active marketplace when the item is on none** —
/// owner's rule as it applies to the sheet that reads this: cash in hand is a
/// sale, so an unlisted item must still be sellable, and an empty picker is a
/// flow with no way out. The fallback is here rather than at the call site so
/// two screens cannot disagree about what an unlisted item may be sold on.
final marketplacesForItemProvider = Provider.family<List<Marketplace>, String>((
  Ref ref,
  String itemId,
) {
  final List<Marketplace> active = ref.watch(activeMarketplacesProvider);
  final List<Marketplace> listed = MarketplaceMatching.matching(
    active,
    ListingMarketplaces.keys(
      ref.watch(listingsForItemProvider(itemId)).value ?? const <Listing>[],
    ),
  );

  return listed.isEmpty ? active : listed;
});

/// The platforms a whole bundle may be sold on.
///
/// **The union of what its items are on, not the intersection.** A bundle is
/// several things the buyer happened to take together, and they are rarely all
/// live on the same platform — an intersection would usually be empty, which
/// is the empty picker `marketplacesForItemProvider` exists to prevent. A
/// bundle where none of the items is listed anywhere gets the full list, the
/// same fallback and for the same reason: cash in hand is a sale.
final marketplacesForItemsProvider =
    Provider.family<List<Marketplace>, List<String>>((
      Ref ref,
      List<String> itemIds,
    ) {
      final List<Marketplace> active = ref.watch(activeMarketplacesProvider);
      final Set<String> keys = <String>{
        for (final String itemId in itemIds)
          ...ListingMarketplaces.keys(
            ref.watch(listingsForItemProvider(itemId)).value ??
                const <Listing>[],
          ),
      };
      final List<Marketplace> listed = MarketplaceMatching.matching(
        active,
        keys,
      );

      return listed.isEmpty ? active : listed;
    });

/// Id → the name the seller gave it. What every row renders through
/// `MarketplaceLabel`.
final Provider<Map<String, String>> marketplaceNamesProvider =
    Provider<Map<String, String>>((Ref ref) {
      return <String, String>{
        for (final Marketplace marketplace
            in ref.watch(marketplacesProvider).value ?? const <Marketplace>[])
          marketplace.id: marketplace.name,
      };
    });

/// Id → the colour every row that names it wears.
///
/// **The only map from a marketplace to a colour.** `AppMarketplaceTag` and
/// `AppMarketplaceDot` read it; no screen looks a hue up itself, so a seller
/// changing one repaints orders, home, payouts and analytics together.
///
/// A deleted marketplace stays in here for the reason it stays in
/// [marketplacesProvider]: a past order still names it.
final Provider<Map<String, AppTagHue>> marketplaceHuesProvider =
    Provider<Map<String, AppTagHue>>((Ref ref) {
      return <String, AppTagHue>{
        for (final Marketplace marketplace
            in ref.watch(marketplacesProvider).value ?? const <Marketplace>[])
          marketplace.id: marketplace.hue,
      };
    });
