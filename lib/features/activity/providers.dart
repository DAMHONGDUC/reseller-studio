/// Riverpod wiring for `activity`. Other features import this file — never
/// anything under `activity/data/` or `activity/presentation/`.
library;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/firestore/workspace_context.dart';
import '../workspace/providers.dart';
import 'data/repositories/firestore_activity_repository.dart';
import 'domain/entities/activity_entry.dart';
import 'domain/repositories/activity_repository.dart';

/// **No mock branch, unlike every other repository provider.**
///
/// The audit log has exactly one writer — Cloud Functions triggers — so there
/// is nothing for an in-memory version to be a stand-in for. Mock mode gets
/// the same empty list a live workspace does until the functions are deployed,
/// and the screen says so rather than inventing a history nobody performed.
final Provider<ActivityRepository?> activityRepositoryProvider =
    Provider<ActivityRepository?>((Ref ref) {
      final WorkspaceContext? context = ref.watch(workspaceContextProvider);

      if (context == null) return null;

      return FirestoreActivityRepository(context);
    });

/// The most recent entries, newest first.
final StreamProvider<List<ActivityEntry>> recentActivityProvider =
    StreamProvider<List<ActivityEntry>>((Ref ref) {
      final ActivityRepository? repository = ref.watch(
        activityRepositoryProvider,
      );

      // Null is signed out or no workspace — both states the shell renders,
      // so an empty stream rather than a throw. Same reasoning as
      // `WorkspaceGuard`, which this cannot use: it guards a repository that
      // throws, and this one is simply absent.
      if (repository == null) {
        return Stream<List<ActivityEntry>>.value(const <ActivityEntry>[]);
      }

      return repository.watchRecent();
    });
