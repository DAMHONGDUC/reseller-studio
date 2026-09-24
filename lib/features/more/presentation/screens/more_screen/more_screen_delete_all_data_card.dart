part of 'more_screen.dart';

/// Empties the open workspace of every business record.
///
/// **Hidden without dev mode**, like the seed card above it, and checked here
/// as well as on the section that holds it: this one deletes, so one of the
/// two guards being forgotten must not be enough.
///
/// Strings are hardcoded English on purpose — developer UI that never reaches
/// a seller, the same exception `_SeedDataCard` takes
/// (hard rule 7).
class _DeleteAllDataCard extends ConsumerWidget {
  const _DeleteAllDataCard();

  /// Asks first, and says what survives. A seller's real workspace is one tap
  /// away from this button, and nothing here is recoverable afterwards.
  Future<void> _confirm(BuildContext context, WidgetRef ref) => showSdDialogV3(
    context,
    SdDialogV3(
      title: 'Delete all data?',
      message:
          'Deletes every item, listing, order, offer, purchase, source, '
          'expense, category, location, marketplace and carrier in this '
          'workspace. The business itself, its members and its activity log '
          'stay. This cannot be undone.',
      icon: AppIconConstant.warning,
      actions: <SdDialogActionV3>[
        SdDialogActionV3(
          label: 'Delete everything',
          isDestructive: true,
          onPressed: () => _delete(context, ref),
        ),
        SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
      ],
    ),
  );

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      final int deleted = await ref
          .read(deleteAllDataControllerProvider.notifier)
          .deleteAll();

      if (!context.mounted) return;

      SdSnackBarUtilsV3.success(context, 'Deleted $deleted documents.');
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

    final bool running = ref.watch(deleteAllDataControllerProvider);
    final bool hasWorkspace = ref.watch(hasWorkspaceProvider);

    return SdCardV3(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SdIconV3(
                AppIconConstant.deleteForever,
                color: context.sdTheme3.danger,
              ),
              SizedBox(width: SdSpacingConstant.w12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Delete all data',
                      style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                        color: context.sdTheme3.textPrimary,
                      ),
                    ),
                    Text(
                      hasWorkspace
                          ? 'Empties this workspace. The business and its '
                                'members stay.'
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
            variant: SdButtonVariantV3.destructive,
            label: 'Delete everything in this workspace',
            icon: AppIconConstant.deleteForever,
            expand: true,
            busy: running,
            onPressed: hasWorkspace ? () => _confirm(context, ref) : null,
          ),
        ],
      ),
    );
  }
}
