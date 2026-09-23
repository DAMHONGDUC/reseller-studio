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
  /// It has to exist because login is *pushed* over the app a guest was
  /// already using — Settings and [requireAccount] both push it — and an
  /// imperative route sits on top of whatever the redirect chose. Without
  /// this, a seller who signs in from a tab signs in successfully and keeps
  /// looking at the login form. `go` is what clears that stack.
  static void afterSignIn(BuildContext context) {
    SdLogger.action(LogTagConstant.navigation, 'Signed in — routing on');

    context.go(AppRoutes.home);
  }

  /// The one place an account is demanded, and the list is short.
  ///
  /// **A guest gets the whole app** (hard rule 1,
  /// `docs/rules/GUEST_MODE.md`), so this no longer stands in front of
  /// creating a record — it stands in front of the handful of things whose
  /// truth a Cloud Function writes, and which would therefore be permanently
  /// empty or permanently wrong without one:
  ///
  /// - the team, because an invitation is addressed to an email account;
  /// - the audit log and the notification inbox (hard rule 12);
  /// - anything that reads another device.
  ///
  /// ```dart
  /// if (!NavigationUtils.requireAccount(context, ref)) return;
  /// ```
  ///
  /// **Never write `if (isGuest)` at a call site instead.** One function
  /// means one place decides what needs an account — which is what kept this
  /// honest through the reversal that deleted everything it used to guard.
  static bool requireAccount(BuildContext context, WidgetRef ref) {
    final bool signedIn = ref.read(isSignedInProvider) ?? false;

    if (signedIn) return true;

    SdLogger.action(
      LogTagConstant.navigation,
      'Account required before action',
      <String, String>{'from': GoRouterState.of(context).matchedLocation},
    );
    // Pushed, not `go`: cancelling sign-in returns the seller to the screen
    // they were looking at rather than dropping them on Home.
    context.push(AppRoutes.login);

    return false;
  }
}
