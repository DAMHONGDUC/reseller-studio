import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';

/// The other screen a seller cannot leave.
///
/// **No app bar, no back, no tabs** — the same shape as the forced update, and
/// for a related reason: the router sends every location here while
/// `accountBlockedProvider` says so, which is what makes the block hold rather
/// than this screen refusing a pop.
///
/// **Signing out is the one action, and it has to be there.** The block is
/// keyed on the email, so a seller with a second account is one tap from a
/// working app; without the button they would have to reinstall to change
/// accounts.
///
/// **It is a UI gate, not a permission.** A blocked account still holds a
/// valid token — what actually refuses it is `firestore.rules`, or disabling
/// the account in the Firebase console.
class AccountBlockedScreen extends ConsumerWidget {
  const AccountBlockedScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthFormState auth = ref.watch(authControllerProvider);

    return SdScaffoldV3(
      body: SdEmptyStateV3(
        icon: AppIconConstant.lock,
        title: context.l10n.accountBlockedTitle,
        message: context.l10n.accountBlockedBody,
        action: SdButtonV3(
          variant: SdButtonVariantV3.secondary,
          label: context.l10n.settingsSignOut,
          busy: auth.isRunning(AccountAction.signOut),
          onPressed: () => _signOut(context, ref),
        ),
      ),
    );
  }
}
