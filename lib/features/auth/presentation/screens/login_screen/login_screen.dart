import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../controllers/auth_controller.dart';
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
/// wherever a third-party sign-in is offered. **Both brand marks are still
/// placeholders** and must be the real ones before submission — Apple and
/// Google each require their own logo and forbid a substitute
/// (`RELEASE_ACTIONS.md`).
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

    return AuthFormShell(
      title: context.l10n.appTitle,
      subtitle: context.l10n.authTagline,
      children: <Widget>[
        SdButtonV3(
          variant: SdButtonVariantV3.primary,
          label: context.l10n.authContinueWithApple,
          icon: Symbols.person_rounded,
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
          icon: Symbols.g_mobiledata_rounded,
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
