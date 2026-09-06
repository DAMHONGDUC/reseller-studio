import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../mock_data/providers.dart';
import '../../../workspace/domain/repositories/workspace_purge_repository.dart';
import '../../../workspace/providers.dart';

/// Empties the workspace that is currently open.
///
/// **Developer-only, and it deletes for real.** It is `DemoSeedController`'s
/// opposite number: the seeder is how a fresh workspace becomes demonstrable,
/// and this is how a workspace full of demo rows becomes the empty one a new
/// seller opens — the state four of the five tabs are hardest to get back to
/// once anything has been written.
///
/// State is just "is it running", so the button can show a spinner. The count
/// comes back from [deleteAll] rather than being held here: the screen shows
/// it once, in a snackbar, and nothing else ever reads it.
class DeleteAllDataController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Returns how many documents were deleted.
  Future<int> deleteAll() async {
    final WorkspacePurgeRepository purge = ref.read(
      workspacePurgeRepositoryProvider,
    );
    final String? workspaceId = ref.read(currentWorkspaceIdProvider);

    state = true;

    try {
      return await purge.deleteAllRecords();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.workspace,
        'Delete all data failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, String>{'workspaceId': workspaceId ?? 'none'},
      );

      rethrow;
    } finally {
      state = false;
    }
  }
}

final NotifierProvider<DeleteAllDataController, bool>
deleteAllDataControllerProvider =
    NotifierProvider<DeleteAllDataController, bool>(
      DeleteAllDataController.new,
    );
