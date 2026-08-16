import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../listings/domain/enums/listing_status.dart';
import '../../../domain/entities/workspace.dart';
import '../../../providers.dart';

/// Team — who can see this workspace and what they may do (plan §24).
///
/// **Read-only in this release.** Inviting a member writes to `invites/`,
/// which `firestore.rules` makes `allow write: if false` — it is a Cloud
/// Function's job, because the callable is what checks the seat limit and
/// what stops the last owner being demoted. Neither function is deployed, so
/// the button says so rather than failing on a permission error the seller
/// cannot act on.
///
/// **Membership is the only ACL** (hard rule 11). Nobody edits their own
/// membership document, which is why there is no role control on your own row.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Member> members = ref.watch(workspaceMembersProvider);
    final Workspace? workspace = ref.watch(currentWorkspaceProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: context.l10n.teamTitle,
        subtitle: workspace?.name,
      ),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          if (members.isEmpty)
            SdEmptyStateV3(
              icon: Symbols.group_rounded,
              title: context.l10n.teamAloneTitle,
              message: context.l10n.teamAloneBody,
            )
          else
            AppListCard(
              children: members
                  .map(
                    (Member member) => AppListRow(
                      title: member.displayName ?? member.email ?? member.uid,
                      subtitle: member.email,
                      icon: Symbols.person_rounded,
                      showChevron: false,
                      trailing: SdBadgeV3(
                        label: RoleLabel.of(context, member.role),
                        tone: member.role == MemberRole.owner
                            ? SdBadgeToneV3.info
                            : SdBadgeToneV3.neutral,
                      ),
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
                  context.l10n.teamInvitesOffTitle,
                  style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
                SizedBox(height: SdSpacingConstant.h6),
                Text(
                  context.l10n.teamInvitesOffBody,
                  style: context.textTheme3.bodySmall!.faint3(context),
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
}
