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
class _LoginActions extends ConsumerWidget {
  const _LoginActions({required this.onSignIn});

  final void Function(AuthProviderKind provider) onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthFormState state = ref.watch(authControllerProvider);
    // Apple's guidelines want the mark in the label's colour, so it is read
    // from the variant rather than assumed.
    final Color appleForeground = SdButtonStyleV3.of(
      context,
      SdButtonVariantV3.primary,
    ).foreground;

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
            variant: SdButtonVariantV3.primary,
            label: context.l10n.authContinueWithApple,
            leading: AuthBrandMark(
              asset: BrandAssetConstant.appleLogo,
              tint: appleForeground,
            ),
            expand: true,
            busy: state.isBusyWith(AuthProviderKind.apple),
            onPressed: state.isBusy
                ? null
                : () => onSignIn(AuthProviderKind.apple),
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SdButtonV3(
            variant: SdButtonVariantV3.outlined,
            label: context.l10n.authContinueWithGoogle,
            // Untinted on purpose — the four-colour "G" is the only form
            // Google's branding guidelines allow.
            leading: const AuthBrandMark(asset: BrandAssetConstant.googleG),
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
