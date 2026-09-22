import 'package:drift/drift.dart';

import '../../../features/carriers/data/dtos/carrier_dto.dart';
import '../../../features/expenses/data/dtos/expense_dto.dart';
import '../../../features/inventory/data/dtos/catalog_dtos.dart';
import '../../../features/inventory/data/dtos/item_dto.dart';
import '../../../features/listings/data/dtos/listing_dto.dart';
import '../../../features/marketplaces/data/dtos/marketplace_dto.dart';
import '../../../features/offers/data/dtos/offer_dto.dart';
import '../../../features/orders/data/dtos/order_dto.dart';
import '../../../features/sourcing/data/dtos/sourcing_dtos.dart';
import '../local_database.dart';
import '../local_row.dart';

/// One table's half of the drain: where the rows are, where they go, and how
/// a stored map becomes the document Firestore should hold.
///
/// **The map is round-tripped through the DTO rather than copied.** A guest
/// row keeps its dates as ISO strings, because SQLite cannot hold a
/// `Timestamp`; pushing that map as-is would leave the account with documents
/// shaped unlike every other one in the collection. `fromMap` then `toMap`
/// costs one pass and lands a native document — and it re-stamps `createdBy`
/// on the way through, which is the restamp `docs/rules/GUEST_MODE.md` calls
/// for, done by the code that already owns the field. `workspaceId` is
/// stamped below it, by `WorkspaceCollections`' own converter — which
/// `FirestoreDrainSink` goes through.
class DrainTable {
  const DrainTable({
    required this.name,
    required this.rows,
    required this.rebuild,
  });

  /// The table it lands in, and what a log line calls it. One value, because
  /// the local table and the Firestore collection have always had the same
  /// name and a second spelling is how they stop.
  final String name;

  final TableInfo<LocalRows, LocalRow> rows;

  final Map<String, Object?> Function(
    String id,
    Map<String, Object?> data,
    String currency,
    String uid,
  )
  rebuild;

  /// Every table, **parents before children** — a row must not land pointing
  /// at one that is not there yet (`docs/rules/GUEST_MODE.md`).
  ///
  /// Adding an entity means adding it here as well as to
  /// `LocalDatabase.drainOrder`, or its rows stay on the device forever.
  static List<DrainTable> all(LocalDatabase db) => <DrainTable>[
    DrainTable(
      name: 'sources',
      rows: db.localSources,
      rebuild: (String id, Map<String, Object?> data, String _, String uid) =>
          SourceDto.toMap(SourceDto.fromMap(id, data), createdBy: uid),
    ),
    DrainTable(
      name: 'purchases',
      rows: db.localPurchases,
      rebuild:
          (String id, Map<String, Object?> data, String currency, String uid) =>
              PurchaseDto.toMap(
                PurchaseDto.fromMap(id, data, fallbackCurrency: currency),
                createdBy: uid,
              ),
    ),
    DrainTable(
      name: 'categories',
      rows: db.localCategories,
      rebuild: (String id, Map<String, Object?> data, String _, String uid) =>
          ItemCategoryDto.toMap(
            ItemCategoryDto.fromMap(id, data),
            createdBy: uid,
          ),
    ),
    DrainTable(
      name: 'locations',
      rows: db.localLocations,
      rebuild: (String id, Map<String, Object?> data, String _, String uid) =>
          StorageLocationDto.toMap(
            StorageLocationDto.fromMap(id, data),
            createdBy: uid,
          ),
    ),
    DrainTable(
      name: 'marketplaces',
      rows: db.localMarketplaces,
      rebuild: (String id, Map<String, Object?> data, String _, String uid) =>
          MarketplaceDto.toMap(
            MarketplaceDto.fromMap(id, data),
            createdBy: uid,
          ),
    ),
    DrainTable(
      name: 'carriers',
      rows: db.localCarriers,
      rebuild: (String id, Map<String, Object?> data, String _, String uid) =>
          CarrierDto.toMap(CarrierDto.fromMap(id, data), createdBy: uid),
    ),
    DrainTable(
      name: 'items',
      rows: db.localItems,
      rebuild:
          (String id, Map<String, Object?> data, String currency, String uid) =>
              ItemDto.toMap(
                ItemDto.fromMap(id, data, fallbackCurrency: currency),
                createdBy: uid,
              ),
    ),
    DrainTable(
      name: 'listings',
      rows: db.localListings,
      rebuild:
          (String id, Map<String, Object?> data, String currency, String uid) =>
              ListingDto.toMap(
                ListingDto.fromMap(id, data, fallbackCurrency: currency),
                createdBy: uid,
              ),
    ),
    DrainTable(
      name: 'orders',
      rows: db.localOrders,
      rebuild:
          (String id, Map<String, Object?> data, String currency, String uid) =>
              OrderDto.toMap(
                OrderDto.fromMap(id, data, fallbackCurrency: currency),
                createdBy: uid,
              ),
    ),
    DrainTable(
      name: 'offers',
      rows: db.localOffers,
      rebuild:
          (String id, Map<String, Object?> data, String currency, String uid) =>
              OfferDto.toMap(
                OfferDto.fromMap(id, data, fallbackCurrency: currency),
                createdBy: uid,
              ),
    ),
    DrainTable(
      name: 'expenses',
      rows: db.localExpenses,
      rebuild:
          (String id, Map<String, Object?> data, String currency, String uid) =>
              ExpenseDto.toMap(
                ExpenseDto.fromMap(id, data, fallbackCurrency: currency),
                createdBy: uid,
              ),
    ),
  ];
}
