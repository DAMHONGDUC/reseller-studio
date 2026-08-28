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
    this.overrides = const <Marketplace, Money>{},
  });

  final Set<Marketplace> selected;

  /// The price every marketplace starts at. Null means the box is empty,
  /// which is "not known" and never zero (hard rule 4). Publish stays
  /// disabled until it parses.
  final Money? price;

  /// **Only the marketplaces priced differently** — owner's rule: each
  /// platform may carry its own price, because they reward different numbers
  /// and take different cuts.
  ///
  /// A map of the exceptions rather than one entry per selected marketplace:
  /// the common case is one price everywhere, and a map filled in eagerly
  /// would make "the seller set this deliberately" indistinguishable from
  /// "the default happened to be copied here".
  final Map<Marketplace, Money> overrides;

  /// What [marketplace] will actually be listed at.
  Money? priceFor(Marketplace marketplace) =>
      overrides[marketplace] ?? price;

  bool isOverridden(Marketplace marketplace) =>
      overrides.containsKey(marketplace);

  /// Every selected marketplace must have a price of its own or a default to
  /// fall back on — an override cannot rescue a platform nobody picked, and
  /// an empty default cannot be published to one without an override.
  bool get canPublish =>
      selected.isNotEmpty &&
      selected.every((Marketplace market) => priceFor(market) != null);

  CrossListState copyWith({
    Set<Marketplace>? selected,
    Money? price,
    Map<Marketplace, Money>? overrides,
  }) => CrossListState(
    selected: selected ?? this.selected,
    // Explicitly nullable: clearing the field has to be able to put the
    // price back to unknown, which `price ?? this.price` could not.
    price: price,
    overrides: overrides ?? this.overrides,
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

  void toggle(Marketplace marketplace) {
    final Set<Marketplace> next = <Marketplace>{...state.selected};
    final Map<Marketplace, Money> overrides = <Marketplace, Money>{
      ...state.overrides,
    };

    if (!next.remove(marketplace)) {
      next.add(marketplace);
    } else {
      // Unticking a platform drops its price with it: a hidden override that
      // came back on the next tick is a number nobody chose this time.
      overrides.remove(marketplace);
    }

    state = CrossListState(
      selected: next,
      price: state.price,
      overrides: overrides,
    );
  }

  void setPrice(Money? price) => state = state.copyWith(price: price);

  /// Price one marketplace on its own. Null clears the override, putting the
  /// platform back on the shared price.
  void setPriceFor(Marketplace marketplace, Money? price) {
    final Map<Marketplace, Money> next = <Marketplace, Money>{
      ...state.overrides,
    };

    if (price == null) {
      next.remove(marketplace);
    } else {
      next[marketplace] = price;
    }

    state = state.copyWith(price: state.price, overrides: next);
  }

  /// Returns how many marketplaces were published to, so the screen can say
  /// so without recounting a set it no longer owns.
  Future<int> publish(Item item) async {
    final CrossListState current = state;

    if (!current.canPublish) return 0;

    // Resolved here, not in the writer: which platform pays what is this
    // form's answer, and `crossList` should be told it rather than asked to
    // re-derive it from a default and a map of exceptions.
    final Map<Marketplace, Money> prices = <Marketplace, Money>{
      for (final Marketplace market in current.selected)
        market: current.priceFor(market)!,
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
