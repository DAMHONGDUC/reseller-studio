import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../auth/providers.dart';
import '../../../../listings/domain/enums/listing_status.dart';
import '../../../domain/entities/workspace.dart';
import '../../../providers.dart';
import '../../widgets/invite_member_sheet.dart';
import '../../widgets/member_actions_sheet.dart';

part 'team_screen_member_row.dart';

/// Team — who can see this workspace and what they may do (plan §24).
///
/// **Membership is the only ACL** (hard rule 11), so everything on this screen
/// is a Cloud Function call: the seat limit needs a count of a collection, the
/// last-owner check needs a count of the owners, and nobody edits their own
/// membership document — none of the three is something a security rule can
/// express. That is also why your own row opens nothing.
///
/// **Pending invitations are not listed here, and cannot be.** An invitation
/// is readable only by the address it names, so "who have I invited" has no
/// server-side answer a client may ask. The invitee sees theirs in the
/// workspace switcher, which is where a business you could join belongs.
///
/// **The add button is absent without a backend.** A widget test has no
/// account and no team repository, so there is nobody to invite
/// and nothing to invite them to — a button that could only fail is worse
/// than none.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Member> members = ref.watch(workspaceMembersProvider);
    final Workspace? workspace = ref.watch(currentWorkspaceProvider);
    final String? uid = ref.watch(currentUidProvider);
    // An affordance, never a permission: `firestore.rules` and the callables
    // decide, and a role that cannot be told reads as allowed so the demo
    // still shows the feature.
    final bool canManage =
        ref.watch(canEditWorkspaceProvider) &&
        ref.watch(teamRepositoryProvider) != null;

    return AppAddFabScaffold(
      appBar: SdAppBarV3(
        title: context.l10n.teamTitle,
        subtitle: workspace?.name,
      ),
      addLabel: context.l10n.teamInvite,
      showAdd: canManage,
      onAdd: () => InviteMemberSheet.show(context),
      body: ListView(
        padding: AppAddFabScaffold.listPadding(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          if (members.isEmpty)
            SdEmptyStateV3(
              icon: AppIconConstant.group,
              title: context.l10n.teamAloneTitle,
              message: context.l10n.teamAloneBody,
            )
          else
            AppListCard(
              children: members
                  .map(
                    (Member member) => _MemberRow(
                      member: member,
                      // Hard rule 11 at the one place it is visible: your own
                      // row is not a control, whoever you are.
                      canManage: canManage && member.uid != uid,
                    ),
                  )
                  .toList(),
            ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          SdCardV3(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.teamRolesTitle,
                  style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
                SizedBox(height: SdSpacingConstant.h6),
                for (final MemberRole role in MemberRole.values)
                  Padding(
                    padding: EdgeInsets.only(top: SdSpacingConstant.h4),
                    child: Text(
                      '${RoleLabel.of(context, role)} — '
                      '${RoleLabel.description(context, role)}',
                      style: context.textTheme3.bodySmall!.faint3(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The words for a role. `domain/` holds none (hard rule 7).
final class RoleLabel {
  static String of(BuildContext context, MemberRole role) => switch (role) {
    MemberRole.owner => context.l10n.roleOwner,
    MemberRole.admin => context.l10n.roleAdmin,
    MemberRole.member => context.l10n.roleMember,
    MemberRole.viewer => context.l10n.roleViewer,
  };

  /// What the role actually permits, in one line.
  ///
  /// **Read from the enum's own getters** (`canWrite`, `canAdminister`,
  /// `canOwn`) rather than written out per case, so a role whose powers change
  /// cannot keep describing itself the old way.
  static String description(BuildContext context, MemberRole role) {
    if (role.canOwn) return context.l10n.roleOwnerDescription;
    if (role.canAdminister) return context.l10n.roleAdminDescription;
    if (role.canWrite) return context.l10n.roleMemberDescription;

    return context.l10n.roleViewerDescription;
  }
}
