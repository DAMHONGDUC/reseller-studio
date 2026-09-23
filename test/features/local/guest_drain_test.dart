import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reseller_studio/core/constants/guest_constant.dart';
import 'package:reseller_studio/core/local/drain/drain_destination.dart';
import 'package:reseller_studio/core/local/drain/drain_sink.dart';
import 'package:reseller_studio/core/local/drain/guest_drain_service.dart';
import 'package:reseller_studio/core/local/local_database.dart';
import 'package:reseller_studio/core/storage/file_uploader.dart';
import 'package:reseller_studio/features/inventory/data/repositories/local_item_repository.dart';
import 'package:reseller_studio/features/inventory/domain/entities/item.dart';
import 'package:reseller_studio/features/inventory/domain/enums/item_status.dart';
import 'package:reseller_studio/features/sourcing/data/repositories/local_sourcing_repositories.dart';
import 'package:reseller_studio/features/sourcing/domain/entities/source.dart';
import 'package:reseller_studio/features/workspace/domain/entities/workspace.dart';

/// The owner's three cases, as three tests
/// (`docs/rules/GUEST_MODE.md`).
///
/// 1. use the app without signing in, then sign in → the records go up, and
///    the device is left holding nothing;
/// 2. sign in, use it, change account → nothing of the first account's is
///    left behind for the second;
/// 3. use it without signing in, delete the app → a fresh install, and the
///    records are gone. Accepted, deliberately, and pinned so nobody "fixes"
///    it by accident.
void main() {
  const String currency = 'USD';
  const String uid = 'uid-real';
  const String destination = 'ws-real';

  late LocalDatabase db;
  late _RecordingSink sink;
  late GuestDrainService drain;
  late LocalItemRepository items;
  late LocalSourceRepository sources;

  Item item(String id, {List<String> photoUrls = const <String>[]}) => Item(
    id: id,
    title: 'Item $id',
    quantity: 1,
    status: ItemStatus.inStock,
    createdAt: DateTime(2026, 1, 1),
    photoUrls: photoUrls,
  );

  setUp(() {
    db = LocalDatabase.forTesting(NativeDatabase.memory());
    sink = _RecordingSink();
    drain = GuestDrainService(db, sink, const _StubUploader());
    items = LocalItemRepository(db, currency: currency);
    sources = LocalSourceRepository(db);
  });

  tearDown(() => db.close());

  group('case 1 — used without signing in, then signed in', () {
    test('every row goes up and the device is left empty', () async {
      await items.saveAll(<Item>[item('a'), item('b')]);
      await sources.save(
        Source(id: 'src-1', name: 'Goodwill', createdAt: DateTime(2026)),
      );

      final int pushed = await drain.run(
        workspaceId: destination,
        uid: uid,
        currency: currency,
      );

      expect(pushed, 3);
      expect(await items.watchItems().first, isEmpty);
      expect(await sources.watchSources().first, isEmpty);
    });

    test('a pushed row is restamped with the real account', () async {
      await items.save(item('a'));

      await drain.run(workspaceId: destination, uid: uid, currency: currency);

      final Map<String, Object?> written = sink.writes.single.data;

      expect(written['createdBy'], uid);
      expect(written['createdBy'], isNot(GuestConstant.uid));
      expect(written['title'], 'Item a');
    });

    test('parents are pushed before children', () async {
      await sources.save(
        Source(id: 'src-1', name: 'Goodwill', createdAt: DateTime(2026)),
      );
      await items.save(item('a'));

      await drain.run(workspaceId: destination, uid: uid, currency: currency);

      expect(sink.writes.map((_Write w) => w.table), <String>[
        'sources',
        'items',
      ]);
    });

    test('a photo on disk is uploaded and the record takes the URL', () async {
      await items.save(item('a', photoUrls: <String>['/tmp/IMG_0001.jpg']));

      await drain.run(workspaceId: destination, uid: uid, currency: currency);

      expect(sink.writes.single.data['photoUrls'], <String>[
        'https://cdn.example/a',
      ]);
    });

    test('a row the server refuses stays on the device', () async {
      await items.saveAll(<Item>[item('good'), item('bad')]);
      sink.refuse.add('bad');

      final int pushed = await drain.run(
        workspaceId: destination,
        uid: uid,
        currency: currency,
      );

      expect(pushed, 1);
      expect((await items.watchItems().first).map((Item i) => i.id), <String>[
        'bad',
      ]);
    });

    test('a resumed drain is not asked again where to go', () async {
      // The destination is the one thing left in the rows cannot answer, so
      // it is the one thing the drain state holds — and reading it back is
      // what stops the dialog reappearing on every launch until the push
      // finishes.
      await items.save(item('a'));
      sink.refuse.add('a');

      await drain.run(workspaceId: destination, uid: uid, currency: currency);

      final String? pending = await drain.pendingDestination();

      expect(pending, destination);
      expect(
        DrainDestination.forAccount(const <Workspace>[]),
        isA<DrainIntoNewWorkspace>(),
        reason: 'and the fresh answer would have been a different one',
      );
    });

    test('a finished drain forgets where it was heading', () async {
      await items.save(item('a'));

      await drain.run(workspaceId: destination, uid: uid, currency: currency);

      expect(await drain.pendingDestination(), isNull);
    });

    test('a resumed drain remembers where it was heading', () async {
      await items.save(item('a'));
      sink.refuse.add('a');

      await drain.run(workspaceId: destination, uid: uid, currency: currency);

      expect(await drain.pendingDestination(), destination);
    });
  });

  group('case 2 — signed in, then a different account', () {
    test('signing out leaves the device holding nothing', () async {
      await items.saveAll(<Item>[item('a'), item('b')]);

      // The Firestore half is not reachable in a unit test; the local wipe is
      // the half that decides whether the next account sees the last one's
      // stock.
      await db.wipe();

      expect(await items.watchItems().first, isEmpty);
    });

    test('a second account drains into its own business', () async {
      await items.save(item('a'));
      await drain.run(
        workspaceId: 'ws-first',
        uid: 'uid-first',
        currency: currency,
      );

      await items.save(item('b'));
      await drain.run(
        workspaceId: 'ws-second',
        uid: 'uid-second',
        currency: currency,
      );

      expect(sink.writes.map((_Write w) => w.id), <String>['a', 'b']);
      expect(sink.writes.last.data['createdBy'], 'uid-second');
    });
  });

  group('case 3 — deleted and reinstalled without signing in', () {
    test(
      'a fresh install has nothing, and that is the accepted cost',
      () async {
        await items.saveAll(<Item>[item('a'), item('b')]);

        // What a reinstall is, from the app's point of view: the file the guest
        // store lived in went with the app, so the next launch opens an empty
        // one. `GuestResetService` is the same wipe, reached deliberately.
        await const GuestResetServiceStub().reinstall(db);

        expect(await items.watchItems().first, isEmpty);
        expect(sink.writes, isEmpty, reason: 'nothing was ever sent anywhere');
      },
    );
  });

  group('which business the records land in', () {
    test('an account with no business takes the guest one whole', () {
      expect(
        DrainDestination.forAccount(const <Workspace>[]),
        isA<DrainIntoNewWorkspace>(),
      );
    });

    test('an account that already has one is asked', () {
      final DrainDestination decision = DrainDestination.forAccount(<Workspace>[
        Workspace(
          id: 'ws-real',
          name: 'Books',
          ownerId: uid,
          country: 'us',
          currency: currency,
          createdAt: DateTime(2026),
        ),
      ]);

      expect(decision, isA<DrainNeedsChoice>());
      expect((decision as DrainNeedsChoice).candidates.single.id, 'ws-real');
    });
  });
}

class _Write {
  const _Write(this.table, this.id, this.data);

  final String table;
  final String id;
  final Map<String, Object?> data;
}

/// A sink that keeps what it was handed, and can refuse a named row.
class _RecordingSink implements DrainSink {
  final List<_Write> writes = <_Write>[];
  final Set<String> refuse = <String>{};

  @override
  Future<void> write({
    required String table,
    required String id,
    required Map<String, Object?> data,
  }) async {
    if (refuse.contains(id)) throw StateError('refused $id');

    writes.add(_Write(table, id, data));
  }
}

class _StubUploader implements FileUploader {
  const _StubUploader();

  @override
  Future<String> upload({
    required FileFolder folder,
    required String recordId,
    required String filePath,
  }) async => 'https://cdn.example/$recordId';

  @override
  Future<void> delete(String url) async {}
}

/// What a reinstall does to the guest store, without a device to delete.
class GuestResetServiceStub {
  const GuestResetServiceStub();

  Future<void> reinstall(LocalDatabase db) => db.wipe();
}
