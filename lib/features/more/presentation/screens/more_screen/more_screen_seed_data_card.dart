part of 'more_screen.dart';

/// Fills the open workspace with the demo business.
///
/// **Hidden without dev mode**, like the delete card beside it and for
/// the same reason: it writes tens of documents into a real workspace.
///
/// Strings are hardcoded English on purpose: this is developer UI that never
/// reaches a seller, and putting it through ARB would mean translating it at
/// release (hard rule 7's exception, which the Developer block takes).
class _SeedDataCard extends ConsumerWidget {
  const _SeedDataCard();

  /// Asks first. It writes tens of documents into a real workspace, and
  /// running it against the wrong business is not something a snackbar undoes.
  Future<void> _confirm(BuildContext context, WidgetRef ref) => showSdDialogV3(
    context,
    SdDialogV3(
      title: 'Seed demo data?',
      message:
          'Writes the demo business into this workspace. Rows with the same '
          'ids are replaced, so running it twice is safe.',
      icon: AppIconConstant.database,
      actions: <SdDialogActionV3>[
        SdDialogActionV3(label: 'Seed', onPressed: () => _seed(context, ref)),
        SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
      ],
    ),
  );

  Future<void> _seed(BuildContext context, WidgetRef ref) async {
    try {
      final int written = await ref
          .read(seedDataControllerProvider.notifier)
          .seed();

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(context, 'Seeded $written documents.');
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
    if (!ref.watch(devModeEnabledProvider)) return const SizedBox.shrink();

    final bool running = ref.watch(seedDataControllerProvider);
    final bool hasWorkspace = ref.watch(hasWorkspaceProvider);

    return SdCardV3(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SdIconV3(
                AppIconConstant.database,
                color: context.sdTheme3.textSecondary,
              ),
              SizedBox(width: SdSpacingConstant.w12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Seed demo data',
                      style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                        color: context.sdTheme3.textPrimary,
                      ),
                    ),
                    Text(
                      hasWorkspace
                          ? 'Writes the demo business into this workspace.'
                          : 'Needs a workspace — sign in and finish setup.',
                      style: context.textTheme3.bodySmall!.muted3(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SdButtonV3(
            variant: SdButtonVariantV3.outlined,
            label: 'Seed this workspace',
            icon: AppIconConstant.download,
            expand: true,
            busy: running,
            onPressed: hasWorkspace ? () => _confirm(context, ref) : null,
          ),
        ],
      ),
    );
  }
}
