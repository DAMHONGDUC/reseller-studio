import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validator_utils.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../../../core/widgets/picker_field.dart';
import '../../../listings/domain/enums/listing_status.dart';
import '../controllers/team_controller.dart';
import '../screens/team_screen/team_screen.dart';

/// Invite somebody by email (plan §28: an email and a role, nothing else).
///
/// **`owner` is not offered.** `inviteMember` refuses it server-side, so a
/// business cannot acquire a second owner by invitation — ownership moves by
/// transfer, which is its own decision and not this sheet's.
///
/// The address is validated here only to save a round trip; the callable
/// checks it again, and it is the callable that decides whether a seat is
/// free.
class InviteMemberSheet extends ConsumerStatefulWidget {
  const InviteMemberSheet({super.key});

  /// The roles an invitation may grant, most privileged first — the same
  /// three `inviteMember` accepts.
  static const List<MemberRole> invitableRoles = <MemberRole>[
    MemberRole.admin,
    MemberRole.member,
    MemberRole.viewer,
  ];

  static Future<void> show(BuildContext context) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) => const InviteMemberSheet(),
  );

  @override
  ConsumerState<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<InviteMemberSheet> {
  final TextEditingController _email = TextEditingController();

  /// Member, not admin: the safe default is the one that can work rather than
  /// the one that can administer.
  MemberRole _role = MemberRole.member;

  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final String email = _email.text.trim();

    if (!ValidatorUtils.isEmail(email)) {
      setState(() => _error = context.l10n.teamInviteEmailInvalid);

      return;
    }

    setState(() => _error = null);

    try {
      await ref
          .read(teamControllerProvider.notifier)
          .invite(email: email, role: _role);

      if (!mounted) return;

      navigator.pop();
      SdSnackBarUtilsV3.success(context, context.l10n.teamInviteSent);
    } catch (error) {
      // Already logged by the controller.
      if (!mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = ref.watch(teamControllerProvider);

    return SdBottomSheetV3(
      title: context.l10n.teamInviteTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SdTextFieldV3(
            label: context.l10n.teamInviteEmail,
            controller: _email,
            hint: context.l10n.teamInviteEmailHint,
            errorText: _error,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: SdSpacingConstant.h16),
          PickerField(
            label: context.l10n.teamRole,
            value: RoleLabel.of(context, _role),
            onTap: () async {
              final MemberRole? picked =
                  await OptionPickerSheet.show<MemberRole>(
                    context,
                    title: context.l10n.teamRole,
                    selected: _role,
                    options: InviteMemberSheet.invitableRoles
                        .map(
                          (MemberRole role) => PickerOption<MemberRole>(
                            value: role,
                            label: RoleLabel.of(context, role),
                            caption: RoleLabel.description(context, role),
                          ),
                        )
                        .toList(),
                  );

              if (picked == null) return;

              setState(() => _role = picked);
            },
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.teamInviteSend,
            expand: true,
            busy: isBusy,
            onPressed: isBusy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
