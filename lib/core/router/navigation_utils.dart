import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/providers.dart';
import '../logging/app_logger.dart';
import 'app_routes.dart';

/// Moves that carry a rule, so a second caller cannot reimplement one without
/// it. A plain "push this route" belongs at its call site.
final class NavigationUtils {
  /// The gate, now that the five tabs render before anyone signs in.
  ///
  /// **This is the whole of hard rule 1's enforcement inside the app**, the
  /// way the router's `redirect` used to be. A signed-out visitor may look at
  /// empty tabs; the moment they try to *do* something, this sends them to
  /// sign in and answers false so the caller stops.
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

    AppLogger.action('Sign-in required before action', <String, String>{
      'from': GoRouterState.of(context).matchedLocation,
    });
    // Pushed, not `go`: cancelling sign-in returns the visitor to the tab
    // they were looking at rather than dropping them on Home.
    context.push(AppRoutes.login);

    return false;
  }
}
