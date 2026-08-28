part of 'team_screen.dart';

/// One teammate: who they are, what they may do, and — for anyone but
/// yourself — a way to change it.
class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.canManage});

  final Member member;

  /// False on your own row and for anyone who cannot administer the business.
  /// The row still renders: a teammate seeing who else is here is not a
  /// permission, and hiding the list would make the screen look broken.
  final bool canManage;

  @override
  Widget build(BuildContext context) => AppListRow(
    title:
        member.displayName ?? member.email ?? context.l10n.teamMemberFallback,
    subtitle: member.email,
    icon: AppIconConstant.person,
    showChevron: canManage,
    onTap: canManage ? () => MemberActionsSheet.show(context, member) : null,
    trailing: SdBadgeV3(
      label: RoleLabel.of(context, member.role),
      tone: member.role == MemberRole.owner
          ? SdBadgeToneV3.info
          : SdBadgeToneV3.neutral,
    ),
  );
}
