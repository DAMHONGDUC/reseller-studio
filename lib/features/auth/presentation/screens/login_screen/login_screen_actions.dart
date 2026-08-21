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
/// **Google draws its own artwork; Apple still draws a glyph.** The
/// four-colour "G" is `assets/brand/google_g.svg`, Google's own file, passed
/// through `leading` so nothing tints it. Apple's logo can only come from
/// Apple, and `assets/brand/apple_logo.svg` does not exist yet — so that
/// button keeps `SimpleIcons.apple`, which renders and is a redrawn
/// trademark. `RELEASE_ACTIONS.md` blocker 5 is the swap, and it is one line.
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
            leading: SvgPicture.asset(BrandAssetConstant.googleG),
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
