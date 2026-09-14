import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/money/money.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../../listings/domain/repositories/listing_repository.dart';
import '../../../listings/domain/services/bulk_listing_plan.dart';
import '../../../listings/providers.dart';
import '../../../marketplaces/domain/entities/marketplace.dart';
import '../../../marketplaces/providers.dart';
import '../../../sourcing/domain/entities/purchase.dart';
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
    required Map<String, Money> prices,
    List<Listing> reprice = const <Listing>[],
  }) async {
    final ListingRepository listings = ref.read(listingRepositoryProvider);
    final ItemRepository items = ref.read(itemRepositoryProvider);
    final DateTime now = DateTime.now();

    if (prices.isEmpty && reprice.isEmpty) return;

    SdLogger.action(LogTagConstant.listing, 'Cross-list item', <String, Object>{
      'itemId': item.id,
      'prices': <String, int>{
        for (final MapEntry<String, Money> entry in prices.entries)
          entry.key: entry.value.minor,
      },
      'repriced': <String, int>{
        for (final Listing listing in reprice)
          listing.marketplaceId: listing.price.minor,
      },
    });

    state = true;

    try {
      // Nothing new to list means nothing to move the item for: a reprice on
      // its own must not re-stamp `listedAt` and reset the staleness clock.
      final bool isNew = prices.isNotEmpty;

      await listings.saveAll(<Listing>[
        // One batch for both halves: a seller who added Depop and cut the
        // eBay price pressed one button, and half of that landing is a state
        // nobody can read back.
        ...reprice,
        for (final MapEntry<String, Money> entry in prices.entries)
          Listing(
            id: _uuid.v4(),
            itemId: item.id,
            marketplaceId: entry.key,
            // Frozen here, at the one moment the record is in hand: renaming
            // the marketplace later must not rewrite what was posted today.
            marketplaceName: _marketplaceName(entry.key),
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
            ? ItemTransition.markListed(item, now: now)
            : item,
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
          'marketplaces': prices.keys.toList(),
        },
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// Put a whole selection up at once (hard rule 16).
  ///
  /// **The plan decides; this only writes it.** Which items are listable, at
  /// what price and on which platforms is `BulkListingPlan`, computed before
  /// the seller confirms so the sheet can say what will be skipped. Working
  /// that out here would put the answer somewhere the sheet could not show it.
  ///
  /// **One `saveAll` for every listing, then one for the items.** Listing day
  /// is a single intent over thirty rows, and a loop of per-item writes is a
  /// state where eleven are up, the screen showed an error, and nobody can
  /// tell which eleven.
  Future<void> crossListAll(BulkListingPlan plan) async {
    final ListingRepository listings = ref.read(listingRepositoryProvider);
    final ItemRepository items = ref.read(itemRepositoryProvider);
    final DateTime now = DateTime.now();

    if (plan.isEmpty) return;

    SdLogger.action(LogTagConstant.listing, 'Bulk cross-list', <String, Object>{
      'items': plan.itemCount,
      'listings': plan.listingCount,
      'skipped': plan.skippedCount,
    });

    state = true;

    try {
      await listings.saveAll(<Listing>[
        for (final BulkListingLine line in plan.lines)
          for (final MapEntry<String, Money> entry in line.prices.entries)
            Listing(
              id: _uuid.v4(),
              itemId: line.item.id,
              marketplaceId: entry.key,
              marketplaceName: _marketplaceName(entry.key),
              title: line.item.title,
              price: entry.value,
              // Draft, like every other listing this app writes: nothing is
              // integrated, so claiming it is live on eBay would be a lie.
              status: ListingStatus.draft,
              createdAt: now,
            ),
      ]);

      await items.saveAll(<Item>[
        for (final BulkListingLine line in plan.lines)
          if (line.item.status.isListable)
            ItemTransition.markListed(line.item, now: now),
      ]);

      SdLogger.info(LogTagConstant.listing, 'Bulk cross-listed', <String, Object>{
        'items': plan.itemCount,
        'listings': plan.listingCount,
      });
      AppAnalytics.instance.bulkAction(
        action: 'Bulk cross-list',
        count: plan.listingCount,
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.listing,
        'Failed to bulk cross-list',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object>{
          'items': plan.itemCount,
          'listings': plan.listingCount,
        },
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// Move every marketplace price on one item or forty (plan §7, hard rule
  /// 16).
  ///
  /// **It writes listings, not items.** The item carries no price of its own
  /// (`lib/features/inventory/CLAUDE.md`), so repricing from Inventory means
  /// moving what each marketplace is asking — one `saveAll`, whether that is
  /// two listings or two hundred.
  ///
  /// **An item on no marketplace is silently skipped**, not an error: a bulk
  /// selection of forty rows where six are drafts is a normal selection, and
  /// refusing the whole write over them would be the bug.
  ///
  /// It deliberately does not re-stamp `listedAt`: moving a price is not
  /// putting the item on sale again, and the staleness clock must not reset.
  Future<void> reprice(List<Item> items, Money price) async {
    final Set<String> itemIds = items.map((Item item) => item.id).toSet();
    final List<Listing> repriced =
        (ref.read(listingsProvider).value ?? const <Listing>[])
            .where((Listing listing) => itemIds.contains(listing.itemId))
            .map((Listing listing) => listing.copyWith(price: price))
            .toList(growable: false);
    final Map<String, Object> data = <String, Object>{
      'items': items.length,
      'listings': repriced.length,
      'priceMinor': price.minor,
    };

    if (repriced.isEmpty) return;

    SdLogger.action(LogTagConstant.listing, 'Reprice listings', data);
    AppAnalytics.instance.bulkAction(
      action: 'Reprice listings',
      count: repriced.length,
    );

    state = true;

    try {
      await ref.read(listingRepositoryProvider).saveAll(repriced);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.listing,
        'Failed to reprice listings',
        error: error,
        stackTrace: stackTrace,
        data: data,
      );

      rethrow;
    } finally {
      state = false;
    }
  }

  /// File items under the buying trip they came off.
  ///
  /// **The trip's source and date travel with it**, for the reason
  /// `ItemFormController.selectPurchase` gives: they are facts about the
  /// purchase, and a second copy of them is a second answer.
  Future<void> assignPurchase(List<Item> items, Purchase purchase) => _bulk(
    'Assign items to purchase',
    items,
    <String, Object>{'purchaseId': purchase.id},
    (Item item) => item.copyWith(
      purchaseId: purchase.id,
      sourceId: purchase.sourceId ?? item.sourceId,
      purchaseDate: purchase.purchaseDate,
    ),
  );

  /// What the marketplace record is called right now, or its id when the
  /// seller has already deleted it.
  String _marketplaceName(String marketplaceId) {
    final List<Marketplace> records =
        ref.read(marketplacesProvider).value ?? const <Marketplace>[];

    return records
            .where((Marketplace record) => record.id == marketplaceId)
            .firstOrNull
            ?.name ??
        marketplaceId;
  }

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
