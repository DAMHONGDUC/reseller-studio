import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_feature_constant.dart';
import '../../../../../core/constants/brand_asset_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/auth_brand_mark.dart';

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
