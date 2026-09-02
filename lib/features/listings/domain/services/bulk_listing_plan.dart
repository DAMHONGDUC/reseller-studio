import '../../../../core/money/money.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/domain/services/item_transition.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../entities/listing.dart';

/// One item and the platforms it is about to go up on.
class BulkListingLine {
  const BulkListingLine({required this.item, required this.prices});

  final Item item;

  /// What this item will be listed at on each platform. Never empty — an item
  /// with nothing left to list is not a line.
  final Map<Marketplace, Money> prices;
}

/// What listing forty items at once would actually do.
///
/// **A plan, computed before anything is written.** Listing day is a batch —
/// a reseller photographs and lists twenty or thirty things in one evening —
/// and hard rule 16 says that is a first-class requirement rather than a
/// later nicety. What made it hard to offer was not the writing but the
/// answering: of forty ticked rows some are already on eBay, some are
/// archived, and some have no price to list at. A bulk action that silently
/// did nothing to nine of them would be worse than no bulk action.
///
/// So this separates the three, and the sheet says so before the seller
/// commits.
///
/// Pure, and it takes the rows rather than reading them: the interesting
/// cases are an item already on every selected platform and one with no
/// expected price, and a service that fetched its own data could be tested at
/// neither.
class BulkListingPlan {
  const BulkListingPlan({
    required this.lines,
    required this.withoutPrice,
    required this.notListable,
    required this.alreadyListed,
  });

  /// What will be written.
  final List<BulkListingLine> lines;

  /// Items with no `expectedPrice`.
  ///
  /// **Skipped, never listed at zero.** A price is what a listing *is*, and a
  /// null one means nobody has said what this is worth (hard rule 4) — not
  /// that it is free.
  final List<Item> withoutPrice;

  /// Items that cannot be listed at all: sold, archived, or none left.
  final List<Item> notListable;

  /// Items already on every platform picked, so there was nothing to add.
  final List<Item> alreadyListed;

  int get itemCount => lines.length;

  int get listingCount => lines.fold(
    0,
    (int running, BulkListingLine line) => running + line.prices.length,
  );

  /// Ticked rows this would do nothing for. The number the sheet has to say
  /// out loud before the seller presses the button.
  int get skippedCount =>
      withoutPrice.length + notListable.length + alreadyListed.length;

  bool get isEmpty => lines.isEmpty;

  /// Work out what listing [items] on [marketplaces] would write.
  ///
  /// [uplift] is a fraction added to each item's expected price — `0.1` puts
  /// everything up 10%, which is what a seller does for a platform that takes
  /// a bigger cut. Zero is the normal case.
  ///
  /// [listings] is every listing the business has; a platform an item is
  /// already on is left alone rather than listed twice.
  factory BulkListingPlan.from({
    required List<Item> items,
    required Set<Marketplace> marketplaces,
    required List<Listing> listings,
    double uplift = 0,
  }) {
    final Map<String, Set<Marketplace>> live = <String, Set<Marketplace>>{};
    final List<BulkListingLine> lines = <BulkListingLine>[];
    final List<Item> withoutPrice = <Item>[];
    final List<Item> notListable = <Item>[];
    final List<Item> alreadyListed = <Item>[];

    for (final Listing listing in listings) {
      live
          .putIfAbsent(listing.itemId, () => <Marketplace>{})
          .add(listing.marketplace);
    }

    for (final Item item in items) {
      if (!ItemTransition.crossListCheck(item).isAllowed) {
        notListable.add(item);

        continue;
      }

      final Money? expected = item.expectedPrice;

      if (expected == null) {
        withoutPrice.add(item);

        continue;
      }

      final Set<Marketplace> already =
          live[item.id] ?? const <Marketplace>{};
      final Map<Marketplace, Money> prices = <Marketplace, Money>{
        for (final Marketplace marketplace in marketplaces)
          if (!already.contains(marketplace))
            marketplace: expected.applyRate(1 + uplift),
      };

      if (prices.isEmpty) {
        alreadyListed.add(item);

        continue;
      }

      lines.add(BulkListingLine(item: item, prices: prices));
    }

    return BulkListingPlan(
      lines: lines,
      withoutPrice: withoutPrice,
      notListable: notListable,
      alreadyListed: alreadyListed,
    );
  }
}
