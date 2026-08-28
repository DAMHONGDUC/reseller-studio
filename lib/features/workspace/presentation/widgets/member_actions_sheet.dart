import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_sheet_action_row.dart';
import '../../../../core/widgets/app_sheet_option_list.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../../domain/entities/workspace.dart';
import '../controllers/team_controller.dart';
import '../screens/team_screen/team_screen.dart';

/// What an admin may do to one teammate: change what they can do, or let them
/// go (plan §24).
///
/// **Never opened on your own row** — hard rule 11: nobody edits their own
/// membership, and the rules refuse it whatever the UI offers. The Team screen
/// is what does not open this on yourself.
///
/// **The last owner is refused by the backend, not here.** That check is a
/// count of the owners in the collection, which a client cannot take and a
/// rule cannot express; the message the callable returns is what the seller
/// sees.
class MemberActionsSheet extends ConsumerWidget {
  const MemberActionsSheet({required this.member, super.key});

  final Member member;

  static Future<void> show(BuildContext context, Member member) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => MemberActionsSheet(member: member),
      );

  Future<void> _changeRole(BuildContext context, WidgetRef ref) async {
    final MemberRole? picked = await OptionPickerSheet.show<MemberRole>(
      context,
      title: context.l10n.teamRole,
      selected: member.role,
      options: MemberRole.values
          .map(
            (MemberRole role) => PickerOption<MemberRole>(
              value: role,
              label: RoleLabel.of(context, role),
              caption: RoleLabel.description(context, role),
            ),
          )
          .toList(),
    );

    if (picked == null || picked == member.role || !context.mounted) return;

    await _run(
      context,
      ref,
      () => ref
          .read(teamControllerProvider.notifier)
          .changeRole(memberUid: member.uid, role: picked),
      context.l10n.teamRoleChanged,
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.teamRemoveConfirmTitle,
        message: context.l10n.teamRemoveConfirmBody(_name(context)),
        icon: Symbols.warning_rounded,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.teamRemove,
            isDestructive: true,
            onPressed: () => _run(
              context,
              ref,
              () =>
                  ref.read(teamControllerProvider.notifier).remove(member.uid),
              context.l10n.teamRemoved,
            ),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  /// Closes the sheet first, so the confirmation is not covered by the sheet
  /// that raised it — the same shape `ItemActionsSheet` uses.
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String done,
  ) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      await action();

      if (!context.mounted) return;

      if (navigator.canPop()) navigator.pop();

      SdSnackBarUtilsV3.success(context, done);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  String _name(BuildContext context) =>
      member.displayName ?? member.email ?? context.l10n.teamMemberFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> actions = <Widget>[
      AppSheetActionRow(
        icon: Symbols.badge_rounded,
        label: context.l10n.teamChangeRole,
        onTap: () => _changeRole(context, ref),
      ),
      AppSheetActionRow(
        icon: Symbols.person_remove_rounded,
        label: context.l10n.teamRemove,
        isDestructive: true,
        onTap: () {
          Navigator.of(context).pop();
          _confirmRemove(context, ref);
        },
      ),
    ];

    return SdBottomSheetV3(
      title: _name(context),
      child: AppSheetOptionList(
        itemCount: actions.length,
        itemBuilder: (BuildContext context, int index) => actions[index],
      ),
    );
  }
}
