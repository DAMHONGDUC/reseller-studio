import '../entities/item.dart';

/// Reading and writing inventory.
///
/// **Streams, not futures, for anything a screen displays.** Firestore's
/// snapshot listeners are how a second device — or a teammate — sees a change
/// without a pull to refresh, and a `Future<List<Item>>` would throw that
/// away and put a refresh button on every screen instead.
///
/// Implementations must never leak a `FirebaseException` past this line:
/// everything goes through `FailureMapper.guard` and arrives as an
/// `AppFailure` (hard rule 6).
abstract interface class ItemRepository {
  /// Every non-deleted item, newest first.
  ///
  /// Filtering by status happens in the presentation layer rather than here.
  /// Inventory shows counts for *all five* tabs at once, so a per-status
  /// query would mean five live listeners for one screen — the whole list is
  /// one listener, and the tabs are a fold over it.
  Stream<List<Item>> watchItems();

  Stream<Item?> watchItem(String id);

  Future<Item?> findById(String id);

  /// Items belonging to one purchase — the `Purchase → Item` half of the
  /// chain, read by the Purchase detail screen.
  Stream<List<Item>> watchItemsForPurchase(String purchaseId);

  /// Create or replace. The caller supplies the id, so an offline create has
  /// a stable identity before the server ever sees it.
  Future<void> save(Item item);

  /// Apply one change to many items at once — bulk reprice, bulk archive.
  ///
  /// Its own method rather than a loop of [save] because hard rule 16 makes
  /// bulk a first-class path: Firestore batches writes, and forty individual
  /// round trips is the difference between instant and a visible wait.
  Future<void> saveAll(List<Item> items);

  /// Soft delete (hard rule 15) — sets `deletedAt`, never removes the row.
  Future<void> delete(String id);
}
