import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../auth/providers.dart';
import '../../providers.dart';

/// Moving between businesses.
///
/// **There is no "current workspace" state to hold.** Switching writes
/// `lastWorkspaceId` on the user's own document; the profile stream carries it
/// back, `resolvedWorkspaceId` picks it up, and every business provider in the
/// app is already watching that. A local copy of "which one is selected" would
/// be a second source of truth that a teammate's change could contradict.
///
/// That is also why the switch survives a reinstall and follows the seller to
/// another device, which a device-local preference would not.
class WorkspaceSwitchController extends Notifier<void> {
  @override
  void build() {}

  /// Point the app at another business the seller already belongs to.
  Future<void> switchTo(String workspaceId) async {
    final String? uid = ref.read(currentUidProvider);

    if (uid == null) {
      SdLogger.error(
        LogTagConstant.workspace,
        'Workspace switch with nobody signed in',
        error: StateError('No uid at workspace switch'),
        data: <String, String>{'workspaceId': workspaceId},
      );

      return;
    }

    if (workspaceId == ref.read(currentWorkspaceIdProvider)) return;

    SdLogger.action(
      LogTagConstant.workspace,
      'Workspace switch requested',
      <String, String>{'workspaceId': workspaceId},
    );

    try {
      await ref
          .read(workspaceRepositoryProvider)
          .setLastWorkspace(uid: uid, workspaceId: workspaceId);
      SdLogger.info(
        LogTagConstant.workspace,
        'Workspace switched',
        <String, String>{'workspaceId': workspaceId},
      );
      AppAnalytics.instance.workspaceSwitched();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.workspace,
        'Workspace switch failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, String>{'workspaceId': workspaceId},
      );

      rethrow;
    }
  }
}
