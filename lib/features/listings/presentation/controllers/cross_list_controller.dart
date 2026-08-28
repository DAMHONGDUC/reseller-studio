import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/money/money.dart';
import '../../../inventory/domain/entities/item.dart';
import '../../../inventory/presentation/controllers/item_actions_controller.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';

/// What the cross-list screen has collected so far (plan §28's cross-listing
/// row: an item, at least one marketplace, and a price that may be inherited).
class CrossListState {
  const CrossListState({
    this.selected = const <Marketplace>{},
    this.price,
    this.prices = const <Marketplace, Money>{},
  });

  final Set<Marketplace> selected;

  /// **The seed, not the answer.** It inherits from the item (§28) and is what
  /// a marketplace's own field starts at the moment it is ticked. Changing it
  /// afterwards does not reach back into rows the seller has already been
  /// shown — a number moving in a field nobody is looking at is worse than
  /// retyping one.
  final Money? price;

  /// What each ticked marketplace will actually be listed at.
  ///
  /// **One entry per selection** — owner's rule: the platforms reward
  /// different numbers and take different cuts, so every row owns its price
  /// rather than sharing one. A null value is a field the seller emptied,
  /// which is "not known" and never zero (hard rule 4).
  final Map<Marketplace, Money> prices;

  /// What [marketplace] will be listed at — its own price, or the seed for a
  /// row that has not been ticked yet.
  Money? priceFor(Marketplace marketplace) => prices[marketplace] ?? price;

  /// Every ticked marketplace needs a price. A row whose field was emptied
  /// holds publish closed rather than quietly falling back to the seed, which
  /// would list at a number the seller had just deleted.
  bool get canPublish =>
      selected.isNotEmpty &&
      selected.every((Marketplace market) => prices[market] != null);

  CrossListState copyWith({
    Set<Marketplace>? selected,
    Money? price,
    Map<Marketplace, Money>? prices,
  }) => CrossListState(
    selected: selected ?? this.selected,
    // Explicitly nullable: clearing the field has to be able to put the
    // price back to unknown, which `price ?? this.price` could not.
    price: price,
    prices: prices ?? this.prices,
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

    state = CrossListState(
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

  /// Returns how many marketplaces were published to, so the screen can say
  /// so without recounting a set it no longer owns.
  Future<int> publish(Item item) async {
    final CrossListState current = state;

    if (!current.canPublish) return 0;

    final Map<Marketplace, Money> prices = <Marketplace, Money>{
      for (final Marketplace market in current.selected)
        market: current.prices[market]!,
    };

    await ref
        .read(itemActionsControllerProvider.notifier)
        .crossList(item, prices: prices, askingPrice: current.price);

    return prices.length;
  }
}

final NotifierProvider<CrossListController, CrossListState>
crossListControllerProvider =
    NotifierProvider<CrossListController, CrossListState>(
      CrossListController.new,
    );
