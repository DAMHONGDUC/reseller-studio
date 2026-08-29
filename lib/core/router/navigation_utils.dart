import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../features/auth/providers.dart';
import '../constants/log_tag_constant.dart';
import 'app_routes.dart';

/// Moves that carry a rule, so a second caller cannot reimplement one without
/// it. A plain "push this route" belongs at its call site.
final class NavigationUtils {
  /// Where a seller goes the moment a session exists.
  ///
  /// **Home is a request, not the destination.** The redirect decides between
  /// Home and workspace setup, so this names the one route that always makes
  /// it run rather than becoming a second answer to "where does a new account
  /// land".
  ///
  /// It has to exist because login is *pushed* over the signed-out shell —
  /// `SignedOutView` and [requireSignIn] both push it — and an imperative
  /// route sits on top of whatever the redirect chose. Without this, a seller
  /// who signs in from a tab signs in successfully and keeps looking at the
  /// login form. `go` is what clears that stack.
  static void afterSignIn(BuildContext context) {
    SdLogger.action(LogTagConstant.navigation, 'Signed in — routing on');

    context.go(AppRoutes.home);
  }

  /// The backstop behind hard rule 1, not the gate itself.
  ///
  /// **Nothing reaches it today.** Four of the five tabs render `SignedOutView`
  /// through `AuthedTab`, and every screen with a create action sits outside
  /// `_previewRoutes` — so a signed-out visitor has nothing to tap. It is kept
  /// because that is a property of the current route table rather than of the
  /// app: unwrap a tab, or put an action on the signed-out shell, and this is
  /// the one thing standing between that and a hole.
  ///
  /// A signed-out visitor may look at empty tabs; the moment they try to *do*
  /// something, this sends them to sign in and answers false so the caller
  /// stops.
  ///
  /// ```dart
  /// if (!NavigationUtils.requireSignIn(context, ref)) return;
  /// ```
  ///
  /// **Never write `if (isSignedIn)` at a call site instead.** One function
  /// means one place decides what "signed in enough to act" means — and when
  /// the bypass is deleted, one place changes.
  static bool requireSignIn(BuildContext context, WidgetRef ref) {
    final bool signedIn = ref.read(isSignedInProvider) ?? false;

    if (signedIn) return true;

    SdLogger.action(
      LogTagConstant.navigation,
      'Sign-in required before action',
      <String, String>{'from': GoRouterState.of(context).matchedLocation},
    );
    // Pushed, not `go`: cancelling sign-in returns the visitor to the tab
    // they were looking at rather than dropping them on Home.
    context.push(AppRoutes.login);

    return false;
  }
}
