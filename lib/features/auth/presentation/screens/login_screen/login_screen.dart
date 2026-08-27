import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_feature_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../controllers/auth_controller.dart';

part 'login_screen_actions.dart';
part 'login_screen_features.dart';
part 'login_screen_header.dart';

/// Login — the gate. **There is no guest mode** (plan principle 1).
///
/// **It sells before it asks.** A seller reaches this screen from a tab they
/// were already browsing, so it has to answer "why hand over an account?"
/// before two buttons mean anything — hence the three feature rows, which are
/// the same three the intro flow shows (`AppFeatureConstant`). Written once,
/// rendered twice: full pages there, compact rows here.
///
/// **Two buttons and nothing else** (owner's rule): Sign in with Apple and
/// Google Sign-In. No email field, no password, no sign-up form, no reset —
/// the identity provider owns all of it, so this app never stores a password
/// and never has to secure a reset flow.
///
/// Apple is not optional beside Google: App Store guideline 4.8 requires it
/// wherever a third-party sign-in is offered. Both marks come from
/// `SimpleIcons` (owner's rule); swapping them for the vendors' own artwork is
/// a submission task, not a build one — `RELEASE_ACTIONS.md` blocker 5.
///
/// **On success it asks the router to re-decide, and nothing more.** This
/// screen is *pushed* over the signed-out shell, and an imperative route sits
/// on top of whatever the redirect chose — so a seller who signed in from a
/// tab would keep looking at this form. `NavigationUtils.afterSignIn` names
/// Home; the redirect is still the one thing that turns that into workspace
/// setup when the account has no business yet.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _signIn(
    BuildContext context,
    WidgetRef ref,
    AuthProviderKind provider,
  ) async {
    try {
      final bool signedIn = await ref
          .read(authControllerProvider.notifier)
          .signIn(provider);

      // False is a cancelled sheet, not a failure — the seller stays here.
      if (!signedIn || !context.mounted) return;

      NavigationUtils.afterSignIn(context);
    } catch (error) {
      // Already logged by the controller; the seller gets the one message
      // hard rule 6 allows. A cancellation never reaches here — the
      // repository reports it as an outcome, not a throw.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only when it was pushed. Sign-in is the front door on a cold start and
    // has nothing to go back to — but it is also pushed over a tab by
    // `NavigationUtils.requireSignIn`, and there it must be escapable.
    final bool canGoBack = Navigator.canPop(context);

    return SdScaffoldV3(
      appBar: canGoBack
          ? SdAppBarV3(title: '', automaticallyImplyLeading: true)
          : null,
      // `bottom: false` — the pinned actions carry the device inset
      // themselves, and a SafeArea here would add the home indicator twice.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: SdContentPaddingV3.horizontal,
                ),
                children: <Widget>[
                  SizedBox(
                    height: canGoBack
                        ? SdContentPaddingV3.topGap
                        : SdSpacingConstant.h40,
                  ),
                  const _LoginHeader(),
                  SizedBox(height: SdSpacingConstant.h32),
                  const _LoginFeatures(),
                ],
              ),
            ),
            _LoginActions(
              onSignIn: (AuthProviderKind provider) =>
                  _signIn(context, ref, provider),
            ),
          ],
        ),
      ),
    );
  }
}
