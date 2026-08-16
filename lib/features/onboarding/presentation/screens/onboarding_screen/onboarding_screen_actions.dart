part of 'onboarding_screen.dart';

/// Skip, in the corner every app puts it.
///
/// It **fades rather than unmounts** on the last page, where the primary
/// button already says the same thing. Removing it would shorten the column
/// and shift the whole page up on the final swipe, which is exactly the kind
/// of jump that makes a screen feel unfinished.
class _SkipRow extends StatelessWidget {
  const _SkipRow({required this.visible, required this.onSkip});

  final bool visible;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(
          top: SdContentPaddingV3.topGap,
          right: SdContentPaddingV3.horizontal,
        ),
        child: AnimatedOpacity(
          duration: SdMotionV3.fast,
          curve: SdMotionV3.standard,
          opacity: visible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !visible,
            // Staying in the tree is what stops the layout jumping, but an
            // invisible button is still read aloud — VoiceOver would offer a
            // Skip that does nothing on the last page.
            child: ExcludeSemantics(
              excluding: !visible,
              child: SdButtonV3(
                variant: SdButtonVariantV3.text,
                label: context.l10n.onboardingSkip,
                size: SdButtonSizeV3.small,
                onPressed: onSkip,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The advance action, holding the bottom edge — the pinned-action rule in
/// `docs/rules/SCREENS.md`.
///
/// One button that changes its word rather than two that swap places: the
/// target stays exactly where the thumb already is across all three pages.
class _PinnedNextAction extends StatelessWidget {
  const _PinnedNextAction({required this.isLast, required this.onPressed});

  final bool isLast;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.pinnedActionsGap,
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.bottom(context),
      ),
      child: SdButtonV3(
        variant: SdButtonVariantV3.primary,
        label: isLast
            ? context.l10n.onboardingStart
            : context.l10n.onboardingNext,
        expand: true,
        onPressed: onPressed,
      ),
    );
  }
}
