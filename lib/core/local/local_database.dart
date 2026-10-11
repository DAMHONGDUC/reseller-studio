import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'local_row.dart';

part 'local_database.g.dart';

/// One guest table: the same three columns for every entity.
///
/// **Deliberately not a column per field.** Every repository in this app reads
/// a whole collection and filters in memory — `FirestoreItemRepository` says
/// so where it explains why soft deletes are not in the query — so the local
/// store needs exactly what those reads need: an id to key on, a date to
/// order by, and the record.
///
/// [data] holds the **same map the Firestore DTO produces**, JSON-encoded
/// (`LocalJsonCodec`). That is what makes the drain a copy rather than a
/// translation, and what stops a guest row and a signed-in row disagreeing
/// about what a field means.
///
/// `workspaceId` and `createdBy` are not columns; they live inside [data]
/// alongside every other field, which is where the drain restamps them.
@UseRowClass(LocalRow)
abstract class LocalRows extends Table {
  TextColumn get id => text()();

  IntColumn get createdAt => integer()();

  TextColumn get data => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@UseRowClass(LocalRow)
class LocalItems extends LocalRows {}

@UseRowClass(LocalRow)
class LocalListings extends LocalRows {}

@UseRowClass(LocalRow)
class LocalOrders extends LocalRows {}

@UseRowClass(LocalRow)
class LocalOffers extends LocalRows {}

@UseRowClass(LocalRow)
class LocalPurchases extends LocalRows {}

@UseRowClass(LocalRow)
class LocalSources extends LocalRows {}

@UseRowClass(LocalRow)
class LocalExpenses extends LocalRows {}

@UseRowClass(LocalRow)
class LocalCategories extends LocalRows {}

@UseRowClass(LocalRow)
class LocalLocations extends LocalRows {}

@UseRowClass(LocalRow)
class LocalMarketplaces extends LocalRows {}

@UseRowClass(LocalRow)
class LocalCarriers extends LocalRows {}

@UseRowClass(LocalRow)
class LocalPricingRules extends LocalRows {}

@UseRowClass(LocalRow)
class LocalListingPriceChanges extends LocalRows {}

/// The guest's own business document. One row, keyed the same way.
@UseRowClass(LocalRow)
class LocalWorkspaces extends LocalRows {}

/// What the drain has to remember across an interruption, and nothing else.
///
/// **There is no per-row bookkeeping** (`docs/rules/GUEST_MODE.md`): a row is
/// deleted once the server confirms it, so what is left in the tables above is
/// exactly what is still owed. The one fact that cannot be recovered that way
/// is which workspace the seller picked in the dialog.
///
/// It lives here rather than in `shared_preferences` so it dies with the data
/// it describes — a stamp that outlived a wipe would claim a push was
/// half-finished for records that no longer exist.
class DrainStates extends Table {
  /// Always [LocalDatabase.drainStateKey]. A single-row table spelled as a
  /// keyed one, because Drift has no other way to say "exactly one".
  TextColumn get key => text()();

  /// The workspace the seller chose to push into.
  TextColumn get destinationWorkspaceId => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

/// Every table a guest writes to.
///
/// **Adding an entity means adding it here and to [LocalDatabase.drainOrder]**,
/// or its rows are never drained — the same trap
/// `WorkspaceCollections.tableNames` exists to close on the Firestore side.
@DriftDatabase(
  tables: <Type>[
    LocalItems,
    LocalListings,
    LocalOrders,
    LocalOffers,
    LocalPurchases,
    LocalSources,
    LocalExpenses,
    LocalCategories,
    LocalLocations,
    LocalMarketplaces,
    LocalCarriers,
    LocalPricingRules,
    LocalListingPriceChanges,
    LocalWorkspaces,
    DrainStates,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(driftDatabase(name: databaseName));

  /// For tests: an in-memory database with no file behind it.
  LocalDatabase.forTesting(super.executor);

  static const String databaseName = 'guest';

  static const String drainStateKey = 'drain';

  /// Version 2 added pricing rules and listing price history.
  @override
  int get schemaVersion => 2;

  /// Every version only ever adds tables, so an upgrade creates the ones the
  /// device does not have yet and touches no existing row.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.createTable(localPricingRules);
        await migrator.createTable(localListingPriceChanges);
      }
    },
  );

  /// The business tables, in the order the drain must push them.
  ///
  /// **Parents before children**, or a row lands pointing at one that is not
  /// there yet (`docs/rules/GUEST_MODE.md`). `localWorkspaces` is absent on
  /// purpose: the destination business is created or chosen before any of
  /// these move.
  List<TableInfo<LocalRows, LocalRow>> get drainOrder =>
      <TableInfo<LocalRows, LocalRow>>[
        localSources,
        localPurchases,
        localCategories,
        localLocations,
        localMarketplaces,
        localCarriers,
        localPricingRules,
        localItems,
        localListings,
        localListingPriceChanges,
        localOrders,
        localOffers,
        localExpenses,
      ];

  /// The tables a guest business is *created* with, written by
  /// `GuestWorkspaceService` and by nothing else.
  ///
  /// **They are records, but they are not the seller's.** Anything asking
  /// "has this seller entered anything yet?" — the Home warning above all —
  /// must skip them, or a business created two seconds ago already looks like
  /// one with something to lose. The drain still pushes them: they are rows,
  /// and the account needs them.
  List<TableInfo<LocalRows, LocalRow>> get seededTables =>
      <TableInfo<LocalRows, LocalRow>>[
        localMarketplaces,
        localCarriers,
        localCategories,
      ];

  /// What the seller themselves has written.
  List<TableInfo<LocalRows, LocalRow>> get sellerTables => drainOrder
      .where(
        (TableInfo<LocalRows, LocalRow> table) => !seededTables.contains(table),
      )
      .toList(growable: false);

  /// Every table holding guest records, for a wipe.
  ///
  /// Not `allTables` — that name is the generated database's own, and Drift
  /// means something wider by it.
  List<TableInfo<LocalRows, LocalRow>> get guestTables =>
      <TableInfo<LocalRows, LocalRow>>[...drainOrder, localWorkspaces];

  /// Empty the device. What sign-out does (`docs/rules/GUEST_MODE.md`).
  Future<void> wipe() => transaction(() async {
    for (final TableInfo<LocalRows, LocalRow> table in guestTables) {
      await delete(table).go();
    }

    await delete(drainStates).go();
  });
}
