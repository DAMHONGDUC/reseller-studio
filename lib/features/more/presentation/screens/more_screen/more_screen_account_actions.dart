part of 'more_screen.dart';

/// Sign out and delete account, and what both share.
///
/// - **deleting asks twice**: once in a dialog that says what goes, once on
///   the provider itself, which re-authenticates a stale sign-in
/// - both rows go inert while either runs, so a second tap cannot start a
///   second delete
final class _AccountActions {
  /// The spinner sits on the row that is working, and only that row.
  static Widget? spinnerFor(AuthFormState auth, AccountAction action) =>
      auth.isRunning(action) ? const SdLoadingV3() : null;

  /// No success message: both actions end the session, and the router replaces
  /// the whole stack with the login screen before a snackbar could be read.
  static Future<void> run(
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
}

class _SignOutRow extends ConsumerWidget {
  const _SignOutRow();

  Future<void> _confirm(BuildContext context, WidgetRef ref) => showSdDialogV3(
    context,
    SdDialogV3(
      title: context.l10n.settingsSignOutConfirmTitle,
      message: context.l10n.settingsSignOutConfirmBody,
      actions: <SdDialogActionV3>[
        SdDialogActionV3(
          label: context.l10n.settingsSignOut,
          isPrimary: true,
          onPressed: () => _AccountActions.run(
            context,
            () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ),
        SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthFormState auth = ref.watch(authControllerProvider);

    return _MoreRowTile(
      icon: AppIconConstant.logout,
      label: context.l10n.settingsSignOut,
      trailing: _AccountActions.spinnerFor(auth, AccountAction.signOut),
      showChevron: false,
      onTap: auth.isBusy ? null : () => _confirm(context, ref),
    );
  }
}

class _DeleteAccountRow extends ConsumerWidget {
  const _DeleteAccountRow();

  Future<void> _confirm(BuildContext context, WidgetRef ref) => showSdDialogV3(
    context,
    SdDialogV3(
      title: context.l10n.settingsDeleteAccountConfirmTitle,
      message: context.l10n.settingsDeleteAccountConfirmBody,
      icon: AppIconConstant.warning,
      actions: <SdDialogActionV3>[
        SdDialogActionV3(
          label: context.l10n.settingsDeleteAccountConfirm,
          isDestructive: true,
          onPressed: () => _AccountActions.run(
            context,
            () => ref.read(authControllerProvider.notifier).deleteAccount(),
          ),
        ),
        SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthFormState auth = ref.watch(authControllerProvider);

    return _MoreRowTile(
      icon: AppIconConstant.deleteForever,
      label: context.l10n.settingsDeleteAccount,
      color: context.sdTheme3.danger,
      trailing: _AccountActions.spinnerFor(auth, AccountAction.deleteAccount),
      showChevron: false,
      onTap: auth.isBusy ? null : () => _confirm(context, ref),
    );
  }
}
