import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/brand_asset_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/auth_brand_mark.dart';
import '../../widgets/auth_form_shell.dart';

/// Login — the gate. **There is no guest mode** (plan principle 1), so this is
/// the first screen anyone without a session reaches, and every route below
/// the shell is unreachable until it is passed.
///
/// **Two buttons and nothing else** (owner's rule): Sign in with Apple and
/// Google Sign-In. No email field, no password, no sign-up form, no reset —
/// the identity provider owns all of it, so this app never stores a password
/// and never has to secure a reset flow.
///
/// Apple is not optional beside Google: App Store guideline 4.8 requires it
/// wherever a third-party sign-in is offered. Both marks are the vendors' own
/// files from `assets/brand/` (`BrandAssetConstant`) — neither may be redrawn,
/// and Google's may not be recoloured.
///
/// The screen navigates nowhere on success: the router's redirect watches auth
/// state and moves the seller on by itself.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _signIn(
    BuildContext context,
    WidgetRef ref,
    AuthProviderKind provider,
  ) async {
    try {
      await ref.read(authControllerProvider.notifier).signIn(provider);
    } catch (error) {
      // Already logged by the controller; the seller gets the one message
      // hard rule 6 allows. A cancellation never reaches here — the
      // repository reports it as an outcome, not a throw.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(context, FailurePresenter.message(context, error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthFormState state = ref.watch(authControllerProvider);
    // Apple's guidelines want the mark in the label's colour, so it is read
    // from the variant rather than assumed.
    final Color appleForeground = SdButtonStyleV3.of(
      context,
      SdButtonVariantV3.primary,
    ).foreground;

    return AuthFormShell(
      title: context.l10n.appTitle,
      subtitle: context.l10n.authTagline,
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
              : () => _signIn(context, ref, AuthProviderKind.apple),
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
              : () => _signIn(context, ref, AuthProviderKind.google),
        ),
        SizedBox(height: SdSpacingConstant.h24),
        Text(
          context.l10n.authPrivacyNote,
          textAlign: TextAlign.center,
          style: context.textTheme3.bodySmall!.faint3(context),
        ),
      ],
    );
  }
}
