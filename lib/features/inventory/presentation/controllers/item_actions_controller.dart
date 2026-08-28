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
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/enums/order_status.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';
import '../../domain/repositories/item_repository.dart';
import '../../domain/services/item_transition.dart';

/// Everything a seller does *to* an item once it exists: list it, sell it,
/// reprice it, move it, archive it — one at a time or forty at once.
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

  /// Put an item on a marketplace (plan §29: listing needs a price and a
  /// marketplace).
  ///
  /// Writes the listing and moves the item in the same call, because a listed
  /// item with no listing — or a listing whose item still says `inStock` — is
  /// a state no screen knows how to render.
  Future<void> listItem(
    Item item, {
    required Marketplace marketplace,
    required Money price,
    String? title,
  }) async {
    final ListingRepository listings = ref.read(listingRepositoryProvider);
    final ItemRepository items = ref.read(itemRepositoryProvider);
    final DateTime now = DateTime.now();
    final String listingId = _uuid.v4();

    SdLogger.action(LogTagConstant.item, 'List item', <String, Object>{
      'itemId': item.id,
      'marketplace': marketplace.name,
      'priceMinor': price.minor,
    });

    state = true;

    try {
      // The item carries the asking price the listing was created at, so the
      // inventory row and the marketplace agree without a join.
      final Item priced = item.copyWith(askingPrice: price);

      await listings.save(
        Listing(
          id: listingId,
          itemId: item.id,
          marketplace: marketplace,
          title: title?.trim().isNotEmpty ?? false ? title!.trim() : item.title,
          price: price,
          // Draft, not active: nothing is integrated yet, so claiming the
          // listing is live on eBay would be a lie the app cannot back up.
          status: ListingStatus.draft,
          createdAt: now,
        ),
      );

      await items.save(
        ItemTransition.apply(priced, ItemStatus.listed, now: now),
      );

      SdLogger.info(LogTagConstant.item, 'Item listed', <String, Object>{
        'itemId': item.id,
        'listingId': listingId,
      });
      AppAnalytics.instance.itemListed(marketplace: marketplace.name);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.item,
        'Failed to list item',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{
          'itemId': item.id,
          'marketplace': marketplace.name,
        },
      );

      rethrow;
    } finally {
      state = false;
    }
  }

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
  /// Marketplaces the item is already on are the caller's to exclude; the
  /// screen greys them out, and passing one anyway would create a second
  /// listing on the same platform.
  Future<void> crossList(
    Item item, {
    required Set<Marketplace> marketplaces,
    required Money price,
  }) async {
    final ListingRepository listings = ref.read(listingRepositoryProvider);
    final ItemRepository items = ref.read(itemRepositoryProvider);
    final DateTime now = DateTime.now();

    if (marketplaces.isEmpty) return;

    SdLogger.action(LogTagConstant.listing, 'Cross-list item', <String, Object>{
      'itemId': item.id,
      'marketplaces': marketplaces.map((Marketplace m) => m.name).toList(),
      'priceMinor': price.minor,
    });

    state = true;

    try {
      final Item priced = item.copyWith(askingPrice: price);

      await listings.saveAll(<Listing>[
        for (final Marketplace marketplace in marketplaces)
          Listing(
            id: _uuid.v4(),
            itemId: item.id,
            marketplace: marketplace,
            // Per-marketplace titles are the point of the entity, but they
            // diverge when a seller optimises one — not at creation, where a
            // second box per platform would be four boxes for one intent.
            title: item.title,
            price: price,
            // Draft, not active: nothing is integrated yet, so claiming the
            // listing is live on eBay would be a lie the app cannot back up.
            status: ListingStatus.draft,
            createdAt: now,
          ),
      ]);

      await items.save(
        item.status.isListable
            ? ItemTransition.apply(priced, ItemStatus.listed, now: now)
            : priced,
      );

      SdLogger.info(
        LogTagConstant.listing,
        'Item cross-listed',
        <String, Object>{'itemId': item.id, 'count': marketplaces.length},
      );
      AppAnalytics.instance.bulkAction(
        action: 'Cross-list item',
        count: marketplaces.length,
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.listing,
        'Failed to cross-list item',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{
          'itemId': item.id,
          'marketplaces': marketplaces.map((Marketplace m) => m.name).toList(),
        },
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// Record a sale (plan §28's manual order).
  ///
  /// **Creates the order as well as moving the item**, because profit is
  /// derived from orders and an item marked sold with no order would vanish
  /// from every figure the product is judged on.
  Future<String> markSold(
    Item item, {
    required Money salePrice,
    required Marketplace marketplace,
    required DateTime soldAt,
    String? buyerName,
  }) async {
    final OrderRepository orders = ref.read(orderRepositoryProvider);
    final ItemRepository items = ref.read(itemRepositoryProvider);
    final String orderId = _uuid.v4();

    SdLogger.action(LogTagConstant.item, 'Mark item sold', <String, Object>{
      'itemId': item.id,
      'marketplace': marketplace.name,
      'salePriceMinor': salePrice.minor,
    });

    state = true;

    try {
      await orders.save(
        Order(
          id: orderId,
          status: OrderStatus.toShip,
          marketplace: marketplace,
          lines: <OrderLine>[
            OrderLine(
              itemId: item.id,
              title: item.title,
              quantity: 1,
              unitPrice: salePrice,
              // Null when nobody entered a cost — the order's profit is then
              // `—` rather than the whole sale price (hard rule 5).
              unitCost: item.purchasePrice,
            ),
          ],
          salePrice: salePrice,
          orderedAt: soldAt,
          buyerName: buyerName,
        ),
      );

      await items.save(
        ItemTransition.apply(
          item.copyWith(askingPrice: item.askingPrice ?? salePrice),
          ItemStatus.sold,
          now: soldAt,
        ),
      );

      SdLogger.info(LogTagConstant.item, 'Item sold', <String, Object>{
        'itemId': item.id,
        'orderId': orderId,
      });
      AppAnalytics.instance.itemSold(
        marketplace: marketplace.name,
        // The share of sales with no cost is the health metric for the whole
        // "insight" half of the product — it is what makes profit unknowable.
        hadCost: item.purchasePrice != null,
      );

      return orderId;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.item,
        'Failed to mark item sold',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{'itemId': item.id},
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

  /// Back onto the shelf from the archive.
  Future<void> restore(List<Item> items) => _bulk(
    'Restore items',
    items,
    const <String, Object>{},
    (Item item) => item.copyWith(status: ItemStatus.inStock),
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
