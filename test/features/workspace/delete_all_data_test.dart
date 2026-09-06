import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reseller_studio/core/firestore/workspace_collections.dart';
import 'package:reseller_studio/features/mock_data/data/in_memory_repositories.dart';
import 'package:reseller_studio/features/mock_data/domain/mock_dataset.dart';
import 'package:reseller_studio/features/mock_data/providers.dart';
import 'package:reseller_studio/features/settings/presentation/controllers/delete_all_data_controller.dart';
import 'package:reseller_studio/features/workspace/domain/repositories/workspace_purge_repository.dart';

import '../../support/pump_app.dart';

/// **What a "delete all data" sweep must leave standing.**
///
/// The developer affordance in More → Settings empties a workspace so the
/// empty screens can be looked at again. Two rows must survive it whatever
/// else goes: the membership that decides every permission (hard rule 11) and
/// the audit log a client may not write at all (hard rule 12) — the first
/// would lock a seller out of a business that still exists, and the second
/// fails the whole sweep on its first row.
class _FailingPurge implements WorkspacePurgeRepository {
  const _FailingPurge();

  @override
  Future<int> deleteAllRecords() async => throw Exception('no backend');
}

void main() {
  group('the table list', () {
    test('sweeps every table but the ACL and the audit log', () {
      expect(WorkspaceCollections.recordTableNames, isNot(contains('members')));
      expect(
        WorkspaceCollections.recordTableNames,
        isNot(contains('activity')),
      );

      // Derived, so a table added to `tableNames` is swept without anyone
      // remembering the second list.
      expect(
        WorkspaceCollections.recordTableNames,
        WorkspaceCollections.tableNames
            .where(
              (String name) => name != 'members' && name != 'activity',
            )
            .toList(),
      );
    });
  });

  group('the sweep', () {
    late MockStore store;
    late WorkspacePurgeRepository purge;

    setUp(() {
      store = MockStore(MockDataset.seed(now: testNow));
      addTearDown(store.dispose);

      purge = InMemoryWorkspacePurgeRepository(store);
    });

    test('empties every record list and reports the count', () async {
      final int deleted = await purge.deleteAllRecords();

      expect(deleted, greaterThan(0));
      expect(store.items, isEmpty);
      expect(store.orders, isEmpty);
      expect(store.listings, isEmpty);
      expect(store.offers, isEmpty);
      expect(store.expenses, isEmpty);
      expect(store.categories, isEmpty);
      expect(store.locations, isEmpty);
      expect(store.sources, isEmpty);
      expect(store.purchases, isEmpty);
      expect(store.marketplaces, isEmpty);
      expect(store.carriers, isEmpty);
    });

    test('leaves the business and its members standing', () async {
      await purge.deleteAllRecords();

      expect(store.workspace, store.dataset.workspace);
      expect(store.dataset.members, isNotEmpty);
    });

    test('running twice deletes nothing the second time', () async {
      await purge.deleteAllRecords();

      expect(await purge.deleteAllRecords(), 0);
    });

    test('the seed card fills it again afterwards', () async {
      await purge.deleteAllRecords();

      await InMemoryItemRepository(store).saveAll(store.dataset.items);

      expect(store.items, hasLength(store.dataset.items.length));
    });
  });

  group('the controller', () {
    test('hands back the count and stops spinning', () async {
      final ProviderContainer container = mockContainer();

      expect(container.read(deleteAllDataControllerProvider), isFalse);

      final int deleted = await container
          .read(deleteAllDataControllerProvider.notifier)
          .deleteAll();

      expect(deleted, greaterThan(0));
      expect(container.read(deleteAllDataControllerProvider), isFalse);
    });

    test('stops spinning when the sweep fails, and rethrows', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          workspacePurgeRepositoryProvider.overrideWithValue(
            const _FailingPurge(),
          ),
        ],
      );

      addTearDown(container.dispose);

      await expectLater(
        container.read(deleteAllDataControllerProvider.notifier).deleteAll(),
        throwsException,
      );
      // The `finally` is what stops a failed run leaving the button busy
      // forever, with no way back but restarting the app.
      expect(container.read(deleteAllDataControllerProvider), isFalse);
    });
  });
}
