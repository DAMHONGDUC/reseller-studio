import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/local/local_database.dart';
import 'package:reseller_studio/core/local/local_table.dart';
import 'package:reseller_studio/features/workspace/data/repositories/local_workspace_purge_repository.dart';

/// The guest half of the Developer section's two buttons: without it a
/// signed-out developer's tap threw `noWorkspace` and did nothing.
void main() {
  late LocalDatabase db;
  late LocalWorkspacePurgeRepository purge;

  setUp(() async {
    final DateTime at = DateTime(2026, 9, 24);

    db = LocalDatabase.forTesting(NativeDatabase.memory());
    purge = LocalWorkspacePurgeRepository(db);

    await LocalTable(db, db.localItems).put('i1', at, <String, Object?>{});
    await LocalTable(db, db.localOrders).put('o1', at, <String, Object?>{});
    await LocalTable(
      db,
      db.localMarketplaces,
    ).put('m1', at, <String, Object?>{});
    await LocalTable(db, db.localCarriers).put('c1', at, <String, Object?>{});
    await LocalTable(db, db.localWorkspaces).put('w1', at, <String, Object?>{});
  });

  tearDown(() => db.close());

  test(
    'delete all empties every record table and keeps the business',
    () async {
      expect(await purge.deleteAllRecords(), 4);
      expect(await LocalTable(db, db.localItems).getAll(), isEmpty);
      expect(await LocalTable(db, db.localMarketplaces).getAll(), isEmpty);
      expect(await LocalTable(db, db.localWorkspaces).getAll(), hasLength(1));
    },
  );

  test('the seeder sweep keeps marketplaces and carriers', () async {
    expect(await purge.deleteRecordsExceptDefaults(), 2);
    expect(await LocalTable(db, db.localItems).getAll(), isEmpty);
    expect(await LocalTable(db, db.localMarketplaces).getAll(), hasLength(1));
    expect(await LocalTable(db, db.localCarriers).getAll(), hasLength(1));
  });
}
