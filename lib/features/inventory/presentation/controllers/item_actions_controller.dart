import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../listings/domain/repositories/listing_repository.dart';
import '../../../marketplaces/domain/enums/marketplace.dart';
import '../../../mock_data/providers.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';
import '../../domain/repositories/item_repository.dart';
import '../../domain/services/item_transition.dart';

/// Everything a seller does *to* an item once it exists: list it, reprice it,
/// move it, archive it — one at a time or forty at once.
///
/// **Selling is not here.** It writes an order, so it belongs to the feature
/// that owns orders — `RecordSaleController`, reached through
/// `orders/providers.dart`. What stays is [check], which the Actions sheet
/// asks before it opens the sheet.
///
/// **The bulk paths are not a loop over the single one.** Hard rule 16 makes
/// bulk first class: `saveAll` batches the write, so forty repriced rows are
/// one round trip rather than forty, and every one of them is checked by the
/// same `ItemTransition` the single path uses.
///
/// Every method logs what it attempted with the data, then rethrows — the log
/// is an extra pair of eyes, never a replacement for the screen's error
/// handling.
class ItemActionsController extends Notifier<bool> {
  static const Uuid _uuid = Uuid();

  /// True while a write is in flight, so a screen can disable its actions.
  @override
  bool build() => false;

  /// Whether [item] may move to [target] right now.
  ///
  /// Exposed so a screen can render *which* requirement is missing before the
  /// seller commits — the domain decides, the screen only picks the words.
  ItemTransitionCheck check(Item item, ItemStatus target) =>
      ItemTransition.check(item, target);

  /// Whether more marketplaces may be added (plan §13).
  ItemTransitionCheck crossListCheck(Item item) =>
      ItemTransition.crossListCheck(item);

  /// Put one item on several marketplaces at once (plan §13).
  ///
  /// **One `saveAll`, not a loop over [listItem].** Cross-listing is a single
  /// user intent that must not half-succeed: four separate writes is a state
  /// where the item is on two marketplaces, the screen showed an error, and
  /// nobody can tell which two.
  ///
  /// **The item's status moves only if it has not already.** An item already
  /// `listed` is exactly the case this exists for — it is on eBay and the
  /// seller wants Depop too — and `ItemTransition.apply` would refuse that
  /// move as `wrongStatus`. What it always gets is the price, because that is
  /// what every new listing was created at.
  ///
  /// **A price per marketplace, not one price for all of them** — owner's
  /// rule. The platforms reward different numbers and take different cuts, so
  /// [prices] carries what each one is actually listed at. The screen resolves
  /// its shared default and its overrides into that map; nothing here has to
  /// know which was which.
  ///
  /// [askingPrice] is what the *item* is worth — the form's shared price, not
  /// any one platform's. Null leaves the item's own asking price alone, which
  /// is right when every platform was priced individually and none of them is
  /// the item's number.
  ///
  /// **[reprice] carries live listings whose price changed** — owner's rule:
  /// one screen answers "what does this cost on each platform", whether the
  /// listing exists yet or not. They ride in the same `saveAll` as the new
  /// ones, because adding a marketplace and correcting another are one
  /// intent when the seller pressed one button.
  ///
  /// Marketplaces the item is already on are the caller's to keep out of
  /// [prices]; the screen ticks them and offers their price instead, and
  /// passing one anyway would create a second listing on the same platform.
  Future<void> crossList(
    Item item, {
    required Map<Marketplace, Money> prices,
    Money? askingPrice,
    List<Listing> reprice = const <Listing>[],
  }) async {
    final ListingRepository listings = ref.read(listingRepositoryProvider);
    final ItemRepository items = ref.read(itemRepositoryProvider);
    final DateTime now = DateTime.now();

    if (prices.isEmpty && reprice.isEmpty) return;

    SdLogger.action(LogTagConstant.listing, 'Cross-list item', <String, Object>{
      'itemId': item.id,
      'prices': <String, int>{
        for (final MapEntry<Marketplace, Money> entry in prices.entries)
          entry.key.name: entry.value.minor,
      },
      'repriced': <String, int>{
        for (final Listing listing in reprice)
          listing.marketplace.name: listing.price.minor,
      },
    });

    state = true;

    try {
      final Item priced = askingPrice == null
          ? item
          : item.copyWith(askingPrice: askingPrice);
      // Nothing new to list means nothing to move the item for: a reprice on
      // its own must not re-stamp `listedAt` and reset the staleness clock.
      final bool isNew = prices.isNotEmpty;

      await listings.saveAll(<Listing>[
        // One batch for both halves: a seller who added Depop and cut the
        // eBay price pressed one button, and half of that landing is a state
        // nobody can read back.
        ...reprice,
        for (final MapEntry<Marketplace, Money> entry in prices.entries)
          Listing(
            id: _uuid.v4(),
            itemId: item.id,
            marketplace: entry.key,
            // Per-marketplace titles are the point of the entity, but they
            // diverge when a seller optimises one — not at creation, where a
            // second box per platform would be four boxes for one intent.
            title: item.title,
            price: entry.value,
            // Draft, not active: nothing is integrated yet, so claiming the
            // listing is live on eBay would be a lie the app cannot back up.
            status: ListingStatus.draft,
            createdAt: now,
          ),
      ]);

      // Going live stamps the staleness clock and makes a draft stock; it is
      // not a status of its own any more.
      await items.save(
        isNew && item.status.isListable
            ? ItemTransition.markListed(priced, now: now)
            : priced,
      );

      SdLogger.info(
        LogTagConstant.listing,
        'Item cross-listed',
        <String, Object>{
          'itemId': item.id,
          'count': prices.length + reprice.length,
        },
      );
      AppAnalytics.instance.bulkAction(
        action: 'Cross-list item',
        count: prices.length + reprice.length,
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.listing,
        'Failed to cross-list item',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{
          'itemId': item.id,
          'marketplaces': prices.keys.map((Marketplace m) => m.name).toList(),
        },
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// Change the asking price on one item or forty (plan §7, hard rule 16).
  Future<void> reprice(List<Item> items, Money price) => _bulk(
    'Reprice items',
    items,
    <String, Object>{'priceMinor': price.minor},
    (Item item) => item.copyWith(askingPrice: price),
  );

  /// Put items on a shelf.
  Future<void> move(List<Item> items, String locationId) => _bulk(
    'Move items',
    items,
    <String, Object>{'locationId': locationId},
    (Item item) => item.copyWith(locationId: locationId),
  );

  /// Withdraw from inventory without a sale — damaged, lost, kept.
  ///
  /// Archiving is deliberately not blocked by anything: a seller doing it is
  /// correcting a mistake, and a rule that stopped the correction would be
  /// the bug.
  Future<void> archive(List<Item> items) => _bulk(
    'Archive items',
    items,
    const <String, Object>{},
    (Item item) => item.copyWith(status: ItemStatus.archived),
  );

  /// Back onto the shelf — from the archive, or from a sale that did not
  /// happen.
  ///
  /// **Through `ItemTransition`, not a bare `copyWith`.** Returning an item is
  /// a state change like any other, and the transition is what knows a sold
  /// date has to go with it; a copy that only moved the status left a row on
  /// the shelf that every export still read as sold.
  Future<void> restore(List<Item> items) => _bulk(
    'Restore items',
    items,
    const <String, Object>{},
    // A recorded instant, not a derived one, so it is the wall clock rather
    // than `clockProvider`.
    (Item item) =>
        ItemTransition.apply(item, ItemStatus.inStock, now: DateTime.now()),
  );

  /// [count] more of each on the shelf, and back in stock with them.
  ///
  /// **One `_bulk`, so forty restocked rows are one write** (hard rule 16),
  /// and every one goes through `ItemTransition.restock` — the count and the
  /// status move together or not at all.
  Future<void> restock(List<Item> items, int count) => _bulk(
    'Restock items',
    items,
    <String, Object>{'count': count},
    // A recorded instant, not a derived one, so it is the wall clock.
    (Item item) => ItemTransition.restock(item, count, now: DateTime.now()),
  );

  /// Onto the shelf: what turns a draft into stock the seller is selling.
  Future<void> makeInStock(List<Item> items) => _bulk(
    'Make items in stock',
    items,
    const <String, Object>{},
    (Item item) =>
        ItemTransition.apply(item, ItemStatus.inStock, now: DateTime.now()),
  );

  /// Soft delete (hard rule 15) — the row stays joinable by the orders and
  /// purchases that reference it.
  Future<void> delete(String itemId) async {
    SdLogger.action(LogTagConstant.item, 'Delete item', <String, Object>{
      'itemId': itemId,
    });

    state = true;

    try {
      await ref.read(itemRepositoryProvider).delete(itemId);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.item,
        'Failed to delete item',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'itemId': itemId},
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// The one write path every bulk edit goes through.
  ///
  /// [describe] is what the log line says; [data] is what it says *about* the
  /// change, so a report six weeks later names the price rather than only the
  /// count.
  Future<void> _bulk(
    String describe,
    List<Item> items,
    Map<String, Object> data,
    Item Function(Item) change,
  ) async {
    if (items.isEmpty) return;

    SdLogger.action(LogTagConstant.item, describe, <String, Object>{
      'count': items.length,
      ...data,
    });
    AppAnalytics.instance.bulkAction(action: describe, count: items.length);

    state = true;

    try {
      await ref
          .read(itemRepositoryProvider)
          .saveAll(items.map(change).toList());
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.item,
        'Failed to $describe',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'count': items.length, ...data},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<ItemActionsController, bool>
itemActionsControllerProvider = NotifierProvider<ItemActionsController, bool>(
  ItemActionsController.new,
);
