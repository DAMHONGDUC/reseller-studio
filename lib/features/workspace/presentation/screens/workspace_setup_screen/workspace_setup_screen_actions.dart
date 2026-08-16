part of 'workspace_setup_screen.dart';

/// The create action, holding the bottom edge instead of scrolling away with
/// the form — owner's rule.
///
/// It sits BELOW the scroll view rather than over it, so the form can never
/// pass behind it. That is why it wears no surface of its own and no blur:
/// [SdContentPaddingV3.pinnedActionsGap] is the whole separation, and the
/// screen's own bottom inset sits under it.
///
/// It watches the controller itself rather than taking the state down as a
/// prop, so a keystroke in the name field rebuilds this button and not the
/// four fields above it.
class _PinnedCreateAction extends ConsumerWidget {
  const _PinnedCreateAction({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WorkspaceSetupState state = ref.watch(
      workspaceSetupControllerProvider,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.pinnedActionsGap,
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.bottom(context),
      ),
      child: SdButtonV3(
        variant: SdButtonVariantV3.primary,
        label: context.l10n.workspaceCreate,
        expand: true,
        busy: state.isSaving,
        onPressed: state.canSubmit ? onSubmit : null,
      ),
    );
  }
}
