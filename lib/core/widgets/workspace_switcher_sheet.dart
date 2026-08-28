import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../features/workspace/domain/entities/pending_invite.dart';
import '../../features/workspace/domain/entities/workspace.dart';
import '../../features/workspace/presentation/controllers/team_controller.dart';
import '../../features/workspace/providers.dart';
import '../constants/app_icon_constant.dart';
import '../error/failure_presenter.dart';
import '../extensions/context_extensions.dart';
import '../router/app_routes.dart';
import 'app_selectable_row.dart';
import 'app_sheet_option_list.dart';
import 'option_picker_sheet.dart';

/// Slack's workspace switcher, in the shape a five-tab app can hold it.
///
/// Slack puts this at the top of a sidebar; there is no sidebar here (hard
/// rule 13 closes the tab list), so the trigger is Home's title and this is
/// what it opens. The parts that matter are kept: every business the seller
/// belongs to, the current one **ticked as well as tinted** (colour is never
/// the only signal), and creating another at the bottom of the same list
/// rather than hidden in settings.
///
/// **Invitations are listed here too**, above the businesses. An invitation
/// is a business you could be in, so this is the surface it belongs on — and
/// it is the only one it can be on: `firestore.rules` scopes `invites/` to
/// the address it names, so the Team screen of the *inviting* business cannot
/// see it and the invitee has nowhere else to look.
///
/// In `core/widgets/` because Home opens it and More will: a widget more than
/// one feature uses cannot live in either feature's `presentation/`.
class WorkspaceSwitcherSheet extends ConsumerWidget {
  const WorkspaceSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => const WorkspaceSwitcherSheet(),
  );

  Future<void> _switch(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    Navigator.of(context).pop();

    try {
      await ref
          .read(workspaceSwitchControllerProvider.notifier)
          .switchTo(workspaceId);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  /// Accepting joins the business **and opens it** — nobody accepts an
  /// invitation in order to keep looking at the one they were already in.
  /// The switch is the controller's; the sheet only closes.
  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    PendingInvite invite,
  ) async {
    Navigator.of(context).pop();

    try {
      await ref.read(teamControllerProvider.notifier).acceptInvite(invite.id);

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(context, context.l10n.teamInviteAccepted);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Workspace> workspaces = ref.watch(workspacesProvider);
    final String? currentId = ref.watch(currentWorkspaceIdProvider);
    final List<PendingInvite> invites =
        ref.watch(pendingInvitesProvider).value ?? const <PendingInvite>[];

    return SdBottomSheetV3(
      title: context.l10n.workspaceSwitchTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Above the list on purpose: an invitation expires in the sense that
          // somebody is waiting on it, and a business you are already in is
          // not going anywhere.
          for (final PendingInvite invite in invites)
            _InviteRow(
              invite: invite,
              onAccept: () => _accept(context, ref, invite),
            ),
          if (invites.isNotEmpty) const SdDividerV3(),
          AppSheetOptionList(
            maxHeight: OptionPickerSheet.listMaxHeight,
            itemCount: workspaces.length,
            itemBuilder: (BuildContext context, int index) {
              final Workspace workspace = workspaces[index];

              return _WorkspaceRow(
                workspace: workspace,
                isCurrent: workspace.id == currentId,
                onTap: () => _switch(context, ref, workspace.id),
                onEdit: () {
                  Navigator.of(context).pop();
                  context.push(AppRoutes.workspaceDetail(workspace.id));
                },
              );
            },
          ),
          const SdDividerV3(),
          _CreateWorkspaceRow(
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.workspaceCreate);
            },
          ),
        ],
      ),
    );
  }
}

class _WorkspaceRow extends StatelessWidget {
  const _WorkspaceRow({
    required this.workspace,
    required this.isCurrent,
    required this.onTap,
    required this.onEdit,
  });

  final Workspace workspace;
  final bool isCurrent;
  final VoidCallback onTap;

  /// Opens the business details screen — owner's rule, on every row and not
  /// only the current one. `firestore.rules` still decides who may write, so
  /// this is an affordance rather than a permission.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final Color accent = context.colorScheme3.primary;

    final TextStyle name = isCurrent
        ? context.textTheme3.bodyMedium!.semiBold3.copyWith(color: accent)
        : context.textTheme3.bodyMedium!.copyWith(
            color: context.sdTheme3.textPrimary,
          );

    return AppSelectableRow(
      // Tapping the one already open is a no-op the controller short-circuits,
      // but leaving it tappable keeps the row heights and hit targets uniform.
      isSelected: isCurrent,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          SdIconTileV3(
            icon: Symbols.storefront_rounded,
            tint: accent,
            filled: isCurrent,
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  workspace.name,
                  style: name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  workspace.currency,
                  style: context.textTheme3.bodySmall!.muted3(context),
                ),
              ],
            ),
          ),
          if (isCurrent) SdIconV3(Symbols.check_rounded, color: accent),
          // Its own tap target beside the row's, so choosing a business and
          // correcting one are never the same gesture. Square and sized to
          // the design system's action slot, so it clears 44pt.
          IconButton(
            onPressed: onEdit,
            tooltip: context.l10n.workspaceEdit,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(
              width: SdAppBarActionV3.slot,
              height: SdAppBarActionV3.slot,
            ),
            icon: SdIconV3(
              Symbols.edit_rounded,
              size: SdIconV3.smallSize,
              color: context.sdTheme3.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A business somebody has asked you to join.
///
/// The name is read off the invitation rather than the workspace document:
/// the invitee cannot read that document until they are a member of it, which
/// is exactly the state this row exists in.
class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite, required this.onAccept});

  final PendingInvite invite;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) => AppSelectableRow(
    isSelected: false,
    onTap: onAccept,
    child: Row(
      children: <Widget>[
        SdIconTileV3(
          icon: Symbols.group_add_rounded,
          tint: context.colorScheme3.primary,
        ),
        SizedBox(width: SdSpacingConstant.w12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                invite.workspaceName ?? context.l10n.teamInviteUnnamed,
                style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                context.l10n.teamInvitePending,
                style: context.textTheme3.bodySmall!.muted3(context),
              ),
            ],
          ),
        ),
        Text(
          context.l10n.teamInviteAccept,
          style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
            color: context.colorScheme3.primary,
          ),
        ),
      ],
    ),
  );
}

class _CreateWorkspaceRow extends StatelessWidget {
  const _CreateWorkspaceRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppSelectableRow(
    // Never the selected one — it is an action, not a business you can be in.
    isSelected: false,
    onTap: onTap,
    child: Row(
      children: <Widget>[
        SdIconV3(AppIconConstant.add, color: context.colorScheme3.primary),
        SizedBox(width: SdSpacingConstant.w12),
        Text(
          context.l10n.workspaceCreateNew,
          style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
            color: context.colorScheme3.primary,
          ),
        ),
      ],
    ),
  );
}
