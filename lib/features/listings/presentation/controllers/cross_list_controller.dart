import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/money/money.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/presentation/controllers/item_actions_controller.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../domain/entities/listing.dart';

/// What the cross-list screen has collected so far (plan §28's cross-listing
/// row: an item, at least one marketplace, and a price that may be inherited).
class CrossListState {
  const CrossListState({
    this.selected = const <Marketplace>{},
    this.price,
    this.prices = const <Marketplace, Money>{},
    this.existing = const <Marketplace, Listing>{},
  });

  /// Marketplaces ticked to be listed on for the first time.
  final Set<Marketplace> selected;

  /// **The seed, not the answer.** It inherits from the item (§28) and is what
  /// a marketplace's own field starts at the moment it is ticked. Changing it
  /// afterwards does not reach back into rows the seller has already been
  /// shown — a number moving in a field nobody is looking at is worse than
  /// retyping one.
  final Money? price;

  /// The number currently in every visible price field, new rows and live
  /// ones alike.
  ///
  /// A null value is a field the seller emptied, which is "not known" and
  /// never zero (hard rule 4).
  final Map<Marketplace, Money> prices;

  /// The listings this item already has, by marketplace.
  ///
  /// **They are editable here** — owner's rule: this is the one screen for
  /// what an item costs on each platform, whether the listing exists yet or
  /// not. Held as the whole `Listing` rather than its price so publishing an
  /// edit is a `copyWith` on the real document, not a lookup done twice.
  final Map<Marketplace, Listing> existing;

  bool isExisting(Marketplace marketplace) =>
      existing.containsKey(marketplace);

  /// What [marketplace] will be listed at — its own number, or the seed for a
  /// row nobody has touched.
  Money? priceFor(Marketplace marketplace) => prices[marketplace] ?? price;

  /// Live listings whose price the seller has changed.
  Map<Marketplace, Money> get repriced => <Marketplace, Money>{
    for (final MapEntry<Marketplace, Listing> entry in existing.entries)
      if (prices[entry.key] != null && prices[entry.key] != entry.value.price)
        entry.key: prices[entry.key]!,
  };

  /// **Publish covers both halves**: new marketplaces and repriced ones. Every
  /// ticked row needs a price — one whose field was emptied holds publish
  /// closed rather than falling back to the seed, which would list at a number
  /// the seller had just deleted.
  bool get canPublish =>
      selected.every((Marketplace market) => prices[market] != null) &&
      (selected.isNotEmpty || repriced.isNotEmpty);

  CrossListState copyWith({
    Set<Marketplace>? selected,
    Money? price,
    Map<Marketplace, Money>? prices,
    Map<Marketplace, Listing>? existing,
  }) => CrossListState(
    selected: selected ?? this.selected,
    // Explicitly nullable: clearing the field has to be able to put the
    // price back to unknown, which `price ?? this.price` could not.
    price: price,
    prices: prices ?? this.prices,
    existing: existing ?? this.existing,
  );
}

/// The cross-listing form (plan §13): pick marketplaces, confirm the price,
/// publish once.
///
/// **The selection lives here rather than in the screen's `State`.** It
/// survives a rebuild, a keyboard opening and a rotation — a set held in the
/// widget resets the moment the shell rebuilds the branch, and the seller
/// watches four ticks disappear.
///
/// The write itself is `ItemActionsController.crossList`: this controller
/// owns what the seller has chosen, that one owns what happens to the item.
class CrossListController extends Notifier<CrossListState> {
  @override
  CrossListState build() => const CrossListState();

  /// Seed the price from the item's asking price (§28: "can inherit from
  /// item"). Called once, when the screen has its item.
  void inheritPrice(Money? price) {
    if (state.price != null) return;

    state = state.copyWith(price: price);
  }

  /// Load the listings the item already has, so their prices are editable
  /// here rather than on a second screen.
  ///
  /// **It fills a field the seller has not touched and never overwrites one
  /// they have** — the stream re-emits on every write, and a teammate saving
  /// something else must not retype this seller's price for them.
  void seedExisting(List<Listing> listings) {
    final Map<Marketplace, Listing> existing = <Marketplace, Listing>{
      for (final Listing listing in listings) listing.marketplace: listing,
    };
    final Map<Marketplace, Money> prices = <Marketplace, Money>{
      ...state.prices,
    };

    for (final MapEntry<Marketplace, Listing> entry in existing.entries) {
      prices.putIfAbsent(entry.key, () => entry.value.price);
    }

    state = state.copyWith(
      price: state.price,
      prices: prices,
      existing: existing,
    );
  }

  /// Tick or untick a marketplace.
  ///
  /// **Ticking seeds that row's price from the shared one**, so the common
  /// case — one number everywhere — is still no typing at all. Unticking
  /// drops the price with it: a hidden number that came back on the next tick
  /// is one nobody chose this time.
  void toggle(Marketplace marketplace) {
    final Set<Marketplace> selected = <Marketplace>{...state.selected};
    final Map<Marketplace, Money> prices = <Marketplace, Money>{
      ...state.prices,
    };

    if (selected.remove(marketplace)) {
      prices.remove(marketplace);
    } else {
      selected.add(marketplace);

      final Money? seed = state.price;

      if (seed != null) prices[marketplace] = seed;
    }

    state = state.copyWith(
      selected: selected,
      price: state.price,
      prices: prices,
    );
  }

  void setPrice(Money? price) => state = state.copyWith(price: price);

  /// Price one marketplace. Null is an emptied field, which holds publish
  /// closed rather than falling back to the seed.
  void setPriceFor(Marketplace marketplace, Money? price) {
    final Map<Marketplace, Money> next = <Marketplace, Money>{...state.prices};

    if (price == null) {
      next.remove(marketplace);
    } else {
      next[marketplace] = price;
    }

    state = state.copyWith(price: state.price, prices: next);
  }

  /// Writes both halves, and returns how many marketplaces were touched — so
  /// the screen can say so without recounting sets it no longer owns.
  Future<int> publish(Item item) async {
    final CrossListState current = state;

    if (!current.canPublish) return 0;

    final Map<Marketplace, Money> created = <Marketplace, Money>{
      for (final Marketplace market in current.selected)
        market: current.prices[market]!,
    };
    final Map<Marketplace, Money> repriced = current.repriced;

    await ref
        .read(itemActionsControllerProvider.notifier)
        .crossList(
          item,
          prices: created,
          askingPrice: current.price,
          reprice: <Listing>[
            for (final MapEntry<Marketplace, Money> entry in repriced.entries)
              current.existing[entry.key]!.copyWith(price: entry.value),
          ],
        );

    return created.length + repriced.length;
  }
}

final NotifierProvider<CrossListController, CrossListState>
crossListControllerProvider =
    NotifierProvider<CrossListController, CrossListState>(
      CrossListController.new,
    );
