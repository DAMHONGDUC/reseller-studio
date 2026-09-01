part of 'workspace_detail_screen.dart';

/// Ending the business, pinned above Save on the screen that owns every other
/// change to it.
///
/// **It is the screen's action, not a row's.** The record this destroys is
/// what the whole screen edits, so it holds the bottom edge like Save does
/// (`docs/rules/SCREENS.md`) — it scrolled off the end of the form until the
/// rule was widened.
///
/// **Only for the business the seller is standing in.** `firestore.rules`
/// scopes member reads to one workspace at a time (hard rule 11b), so the app
/// cannot tell what role you hold in a business you are not in — and offering
/// to destroy a record on a permission it cannot read is the one place a
/// guessed affordance is not acceptable. Editing is offered either way,
/// because a refused write costs a message and a refused delete would have
/// cost the business.
class _DangerZone extends ConsumerWidget {
  const _DangerZone({required this.workspace});

  final Workspace workspace;

  /// **Asks once, in a dialog that says exactly what goes.** There is no undo
  /// and no export first — the same shape as deleting the account, which is
  /// the only other control in the app that destroys records.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.workspaceDeleteConfirmTitle,
        message: context.l10n.workspaceDeleteConfirmBody(workspace.name),
        icon: AppIconConstant.warning,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.workspaceDeleteConfirm,
            isDestructive: true,
            onPressed: () => _delete(context, ref),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  /// No success message: the router replaces the screen the moment the profile
  /// stream drops the id, so a message would be posted onto a route that is
  /// already gone.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(workspaceDetailControllerProvider.notifier)
          .delete(workspace.id);
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
    final bool isCurrent =
        ref.watch(currentWorkspaceIdProvider) == workspace.id;

    if (!isCurrent || !ref.watch(canDeleteWorkspaceProvider)) {
      return const SizedBox.shrink();
    }

    // Its own gap: this button is conditional, and a gap owned by the pinned
    // slot would leave a hole above Save for everyone who cannot delete.
    return Padding(
      padding: EdgeInsets.only(bottom: SdSpacingConstant.h12),
      child: SdButtonV3(
        variant: SdButtonVariantV3.destructive,
        label: context.l10n.workspaceDelete,
        icon: AppIconConstant.deleteForever,
        expand: true,
        onPressed: () => _confirm(context, ref),
      ),
    );
  }
}
