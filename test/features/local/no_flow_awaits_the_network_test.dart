import 'package:drift/native.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/local/drain/drain_sink.dart';
import 'package:reseller_studio/core/local/drain/guest_drain_service.dart';
import 'package:reseller_studio/core/local/local_database.dart';
import 'package:reseller_studio/core/storage/file_uploader.dart';
import 'package:reseller_studio/features/inventory/data/repositories/local_item_repository.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';

/// **No user-facing flow ever awaits the network** — the invariant the whole
/// guest design exists to keep (`docs/rules/GUEST_MODE.md`).
///
/// The strongest form of it this app can assert: with no Firebase app
/// initialised at all — the state a device with no config, and a fair stand-in
/// for one with no signal — a seller still saves, reads and deletes.
void main() {
  late LocalDatabase db;
  late LocalItemRepository items;

  Item item(String id) => Item(
    id: id,
    title: 'Item $id',
    quantity: 1,
    status: ItemStatus.inStock,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    db = LocalDatabase.forTesting(NativeDatabase.memory());
    items = LocalItemRepository(db, currency: 'USD');
  });

  tearDown(() => db.close());

  test('there is no Firebase app in this test, which is the point', () {
    expect(Firebase.apps, isEmpty);
  });

  test('a guest saves, reads and deletes with no backend at all', () async {
    await items.save(item('a3f1'));

    expect((await items.findById('a3f1'))?.title, 'Item a3f1');

    await items.delete('a3f1');

    expect(await items.watchItems().first, isEmpty);
  });

  test('a save does not wait on the thing that would have failed', () async {
    // The remote half throwing is what the sibling app's spec asks this test
    // to prove survivable. Here it cannot even be reached from a save: the
    // sink is only touched by the drain.
    final GuestDrainService drain = GuestDrainService(
      db,
      const _ThrowingSink(),
      const _ThrowingUploader(),
    );

    await items.save(item('a3f1'));

    expect((await items.findById('a3f1'))?.title, 'Item a3f1');

    // And the drain failing leaves the record exactly where the seller left
    // it, rather than losing it to a backend that was not there.
    await drain.run(workspaceId: 'ws', uid: 'uid', currency: 'USD');

    expect((await items.findById('a3f1'))?.title, 'Item a3f1');
  });
}

class _ThrowingSink implements DrainSink {
  const _ThrowingSink();

  @override
  Future<void> write({
    required String table,
    required String id,
    required Map<String, Object?> data,
  }) async => throw StateError('no network');
}

class _ThrowingUploader implements FileUploader {
  const _ThrowingUploader();

  @override
  Future<String> upload({
    required FileFolder folder,
    required String recordId,
    required String filePath,
  }) async => throw StateError('no network');

  @override
  Future<void> delete(String url) async => throw StateError('no network');
}
