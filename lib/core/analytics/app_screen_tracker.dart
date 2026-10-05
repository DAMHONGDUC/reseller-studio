import 'package:go_router/go_router.dart';
import 'package:system_design/common.dart';

import '../constants/log_tag_constant.dart';
import '../router/app_routes.dart';
import 'app_analytics.dart';

/// Reports every screen the router brings to the top, except a tab's root.
///
/// **It listens to the router delegate, not a navigator.** A navigator
/// observer sees one navigator, and this app has six — the root and one per
/// tab branch. The delegate's configuration is the whole stack, and its
/// top-most template is the screen the seller is looking at.
///
/// - **The template, never the location**: `/orders/:orderId`, not
///   `/orders/ord-4`, so one screen is one series and no id leaves the device.
/// - **A tab's root is `AppShell`'s** (`AppAnalytics.tabViewed`), which knows
///   a tab switch from a pop; reporting it here as well would count it twice.
/// - **Only a change is a view**: a refresh that lands on the same template
///   reports nothing.
final class AppScreenTracker {
  AppScreenTracker(this._router);

  final GoRouter _router;

  String? _last;

  void attach() => _router.routerDelegate.addListener(_onChange);

  void detach() => _router.routerDelegate.removeListener(_onChange);

  void _onChange() {
    // `state` reads the last match, which an empty configuration has none of.
    final String? screen = _router.routerDelegate.currentConfiguration.isEmpty
        ? null
        : _router.state.fullPath;

    if (screen == null || screen.isEmpty || screen == _last) return;

    _last = screen;

    if (AppRoutes.tabRoots.contains(screen)) return;

    SdLogger.info(LogTagConstant.navigation, 'Screen viewed', <String, String>{
      'screen': screen,
    });
    AppAnalytics.instance.screenViewed(screen: screen);
  }
}
