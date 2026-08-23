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
  });

  final Set<Marketplace> selected;

  /// Null means the box is empty, which is "not known" and never zero
  /// (hard rule 4). Publish stays disabled until it parses.
  final Money? price;

  bool get canPublish => selected.isNotEmpty && price != null;

  CrossListState copyWith({Set<Marketplace>? selected, Money? price}) =>
      CrossListState(
        selected: selected ?? this.selected,
        // Explicitly nullable: clearing the field has to be able to put the
        // price back to unknown, which `price ?? this.price` could not.
        price: price,
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

    if (!next.remove(marketplace)) next.add(marketplace);

    state = CrossListState(selected: next, price: state.price);
  }

  void setPrice(Money? price) => state = state.copyWith(price: price);

  /// Returns how many marketplaces were published to, so the screen can say
  /// so without recounting a set it no longer owns.
  Future<int> publish(Item item) async {
    final CrossListState current = state;
    final Money? price = current.price;

    if (price == null || current.selected.isEmpty) return 0;

    await ref
        .read(itemActionsControllerProvider.notifier)
        .crossList(item, marketplaces: current.selected, price: price);

    return current.selected.length;
  }
}

final NotifierProvider<CrossListController, CrossListState>
crossListControllerProvider =
    NotifierProvider<CrossListController, CrossListState>(
      CrossListController.new,
    );
