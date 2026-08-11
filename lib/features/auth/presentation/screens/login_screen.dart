import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';

/// Login — the gate. **There is no guest mode** (plan principle 1), so this
/// is the first screen anyone without a session reaches, and every route
/// below the shell is unreachable until it is passed.
///
/// The plan (§26) asks for email/password, Sign in with Apple and Google
/// Sign-In. Apple is not optional once Google ships: App Store guideline 4.8
/// requires it whenever a third-party sign-in is offered.
///
/// Scaffolded: the frame and fields are real, the credentials go nowhere.
/// Wiring this means a `LoginController` under
/// `presentation/controllers/` — the screen stays a `ConsumerWidget` that
/// watches state and calls methods, and never talks to `FirebaseAuth`
/// itself.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    body: SafeArea(
      child: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdSpacingConstant.h64),
          Text(
            context.l10n.appTitle,
            style: context.textTheme3.headlineMedium!.bold3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Text(
            'Source, list, sell, ship, profit.',
            style: context.textTheme3.bodyMedium!.muted3(context),
          ),
          SizedBox(height: SdSpacingConstant.h40),
          SdTextFieldV3(
            label: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.email],
          ),
          SizedBox(height: SdSpacingConstant.h16),
          SdTextFieldV3(
            label: 'Password',
            controller: _password,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.password],
          ),
          SizedBox(height: SdSpacingConstant.h24),
          SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: 'Sign in',
            expand: true,
            onPressed: () {},
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SdButtonV3(
            variant: SdButtonVariantV3.outlined,
            label: 'Continue with Apple',
            // Placeholder glyph. Both brand marks must be the real ones
            // before this ships — Apple and Google each require their own
            // logo and forbid a substitute in a sign-in button.
            icon: Symbols.person_rounded,
            expand: true,
            onPressed: () {},
          ),
          SizedBox(height: SdSpacingConstant.h12),
          SdButtonV3(
            variant: SdButtonVariantV3.outlined,
            label: 'Continue with Google',
            icon: Symbols.g_mobiledata_rounded,
            expand: true,
            onPressed: () {},
          ),
        ],
      ),
    ),
  );
}
