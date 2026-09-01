part of 'login_screen.dart';

/// The two ways in, holding the bottom edge.
///
/// Pinned rather than scrolled with the content — the pinned-action rule in
/// `docs/rules/SCREENS.md`. A seller who has read enough should never have to
/// scroll to find out how to start, and the buttons are the only thing on this
/// screen that does anything.
///
/// It watches the controller itself rather than taking the state down as a
/// prop, so a sign-in in flight rebuilds these two buttons and not the feature
/// list above them.
///
/// **Both buttons wear `SdButtonVariantV3.vendor`** — black on a light theme,
/// white on a dark one, and never the app's indigo. Apple allows its sign-in
/// button in black, white, or white with an outline and nothing else, so the
/// old `primary` styling was a rejection waiting at review rather than a
/// style preference. Google's neutral button is the same shape.
///
/// **Both are the same size, and it is `small`** — the pair is read as one
/// control with two options, so a difference in height between them reads as
/// a bug rather than as emphasis. Whatever they wear, they wear together.
///
/// **Both marks are `SimpleIcons` glyphs** (owner's rule, hard rule 1) — a
/// font, not the vendors' own artwork, so nothing here can fail to load and
/// take the only way into the app down with it. Google's real file exists and
/// is deliberately not used: two buttons drawn two different ways is the state
/// where only one of them can break. Both swap to `leading` at once, before an
/// external build — `RELEASE_ACTIONS.md` blocker 5.
class _LoginActions extends ConsumerWidget {
  const _LoginActions({required this.onSignIn});

  final void Function(AuthProviderKind provider) onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthFormState state = ref.watch(authControllerProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.pinnedActionsGap,
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.bottom(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SdButtonV3(
            variant: SdButtonVariantV3.vendor,
            label: context.l10n.authContinueWithApple,
            icon: SimpleIcons.apple,
            size: SdButtonSizeV3.small,
            expand: true,
            busy: state.isBusyWith(AuthProviderKind.apple),
            onPressed: state.isBusy
                ? null
                : () => onSignIn(AuthProviderKind.apple),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SdButtonV3(
            variant: SdButtonVariantV3.vendor,
            label: context.l10n.authContinueWithGoogle,
            icon: SimpleIcons.google,
            size: SdButtonSizeV3.small,
            expand: true,
            busy: state.isBusyWith(AuthProviderKind.google),
            onPressed: state.isBusy
                ? null
                : () => onSignIn(AuthProviderKind.google),
          ),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            context.l10n.authPrivacyNote,
            textAlign: TextAlign.center,
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
        ],
      ),
    );
  }
}
