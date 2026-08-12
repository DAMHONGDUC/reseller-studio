part of 'settings_screen.dart';

/// Who is signed in, and the two ways out.
///
/// **Deleting the account is destructive and irreversible, so it asks twice**
/// — once in a dialog that says what goes, and once by refusing to proceed on
/// a stale session. Firebase rejects a delete on an old sign-in with
/// `requires-recent-login`, which arrives as `unauthenticated`; the message
/// tells the seller to sign in again rather than showing a failure they
/// cannot act on.
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

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
          SdDialogActionV3(
            label: context.l10n.actionCancel,
            onPressed: () {},
          ),
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
        icon: Symbols.warning_rounded,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.settingsDeleteAccountConfirm,
            isDestructive: true,
            onPressed: () => _run(
              context,
              () => ref.read(authControllerProvider.notifier).deleteAccount(),
            ),
          ),
          SdDialogActionV3(
            label: context.l10n.actionCancel,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  /// No success message: both actions end the session, and the router replaces
  /// the whole stack with the login screen before a snackbar could be read.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? email = ref.watch(authUserProvider).value?.email;
    final String? name = ref.watch(authUserProvider).value?.displayName;
    final bool isBypassed = DevFlags.bypassAuth;

    return AppListCard(
      children: <Widget>[
        AppListRow(
          title: name ?? email ?? context.l10n.settingsSignedIn,
          subtitle: isBypassed ? context.l10n.settingsBypassAccount : email,
          icon: Symbols.person_rounded,
          showChevron: false,
        ),
        AppListRow(
          title: context.l10n.settingsSignOut,
          icon: Symbols.logout_rounded,
          iconTint: context.sdTheme3.textSecondary,
          showChevron: false,
          onTap: () => _confirmSignOut(context, ref),
        ),
        AppListRow(
          title: context.l10n.settingsDeleteAccount,
          subtitle: context.l10n.settingsDeleteAccountPermanent,
          icon: Symbols.delete_forever_rounded,
          iconTint: context.sdTheme3.danger,
          showChevron: false,
          onTap: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }
}
