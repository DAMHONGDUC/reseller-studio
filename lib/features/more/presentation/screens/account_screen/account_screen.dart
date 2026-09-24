import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../auth/providers.dart';

/// Who is signed in, and the two ways out.
///
/// Pushed from the Account row on More — that row only ever says "Signed
/// in", never the email or the name (nothing on More prints one); this
/// screen is where a seller actually reads them.
///
/// **Deleting the account is destructive and irreversible, so it asks
/// twice** — once in a dialog that says what goes, and once on the provider
/// itself. The backend refuses a delete on a sign-in more than a few minutes
/// old, and the repository answers that by raising the Apple or Google sheet
/// and trying again, so the seller confirms with the account rather than
/// being told to sign out and come back.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.settingsSignOutConfirmTitle,
        message: context.l10n.settingsSignOutConfirmBody,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.settingsSignOut,
            isPrimary: true,
            onPressed: () => _run(
              context,
              () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.settingsDeleteAccountConfirmTitle,
        message: context.l10n.settingsDeleteAccountConfirmBody,
        icon: AppIconConstant.warning,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.settingsDeleteAccountConfirm,
            isDestructive: true,
            onPressed: () => _run(
              context,
              () => ref.read(authControllerProvider.notifier).deleteAccount(),
            ),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  /// The spinner sits on the row that is working, and only that row: the
  /// delete takes seconds the seller cannot otherwise see, and both rows go
  /// inert while either runs so a second tap cannot start a second delete.
  static Widget? _spinnerFor(AuthFormState auth, AccountAction action) =>
      auth.isRunning(action) ? const SdLoadingV3() : null;

  /// No success message: both actions end the session, and the router
  /// replaces the whole stack with the login screen before a snackbar could
  /// be read.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
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
    final String? email = ref.watch(authUserProvider).value?.email;
    final String? name = ref.watch(authUserProvider).value?.displayName;
    final AuthFormState auth = ref.watch(authControllerProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.settingsAccount),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          AppListCard(
            children: <Widget>[
              AppListRow(
                title: name ?? email ?? context.l10n.settingsSignedIn,
                // The email is the second fact, so it only shows once a name
                // is already the title — printed once, never twice.
                subtitle: name != null ? email : null,
                icon: AppIconConstant.person,
                showChevron: false,
              ),
              AppListRow(
                title: context.l10n.settingsSignOut,
                icon: AppIconConstant.logout,
                iconTint: context.sdTheme3.textSecondary,
                trailing: _spinnerFor(auth, AccountAction.signOut),
                showChevron: false,
                onTap: auth.isBusy ? null : () => _confirmSignOut(context, ref),
              ),
              AppListRow(
                title: context.l10n.settingsDeleteAccount,
                icon: AppIconConstant.deleteForever,
                iconTint: context.sdTheme3.danger,
                trailing: _spinnerFor(auth, AccountAction.deleteAccount),
                showChevron: false,
                onTap: auth.isBusy ? null : () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
