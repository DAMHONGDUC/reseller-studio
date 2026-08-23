part of 'cross_list_screen.dart';

/// Publish, holding the bottom edge instead of scrolling away with the form —
/// owner's rule, the same shape as workspace setup's create action.
///
/// It watches both controllers itself rather than taking them down as props:
/// one keystroke in the price field then rebuilds this button and not the
/// marketplace list above it.
class _PinnedPublishAction extends ConsumerWidget {
  const _PinnedPublishAction({required this.onPublish});

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CrossListState state = ref.watch(crossListControllerProvider);
    final bool isBusy = ref.watch(itemActionsControllerProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.pinnedActionsGap,
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.bottom(context),
      ),
      child: SdButtonV3(
        variant: SdButtonVariantV3.primary,
        // Names the count, so the seller commits to a number rather than to a
        // verb — "Publish to 3 marketplaces" is checkable at a glance.
        label: state.selected.isEmpty
            ? context.l10n.crossListPublish
            : context.l10n.crossListPublishCount(state.selected.length),
        expand: true,
        busy: isBusy,
        onPressed: state.canPublish && !isBusy ? onPublish : null,
      ),
    );
  }
}
