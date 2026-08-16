import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:seller_os/core/router/app_navigator_key.dart';
import 'package:seller_os/core/router/app_router.dart';
import 'package:seller_os/core/router/app_routes.dart';
import 'package:seller_os/features/auth/providers.dart';
import 'package:seller_os/features/workspace/providers.dart';

/// **The glass nav bar belongs to the five tab screens and to nothing else.**
/// Owner's rule.
///
/// A route nested in a `StatefulShellBranch` is pushed onto that *branch's*
/// navigator by default, which leaves the shell — and its bar — drawn over
/// the top of it. That is why Expenses and Categories had content sitting
/// under the bar: they are reached from More, so they looked like pushed
/// routes and were not.
///
/// Naming `AppNavigatorKey.root` as a route's `parentNavigatorKey` pushes it
/// above the shell instead. This test is structural rather than visual on
/// purpose: it fails the moment a new detail route is added without the key,
/// which is when the mistake is cheap.
void main() {
  /// The five branch roots — the only screens that keep the bar.
  const Set<String> tabs = <String>{
    AppRoutes.home,
    AppRoutes.inventory,
    AppRoutes.orders,
    AppRoutes.analytics,
    AppRoutes.more,
  };

  GoRouter buildRouter() {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        // The router reads both while it is being constructed. Overridden so
        // the test never reaches FirebaseAuth, which throws with no app.
        isSignedInProvider.overrideWithValue(true),
        workspaceStatusProvider.overrideWithValue(WorkspaceStatus.ready),
      ],
    );

    addTearDown(container.dispose);

    return container.read(routerProvider);
  }

  /// Every route under the shell, paired with the path it resolves to.
  List<(GoRoute, String)> shellRoutes(GoRouter router) {
    final List<(GoRoute, String)> found = <(GoRoute, String)>[];

    void walk(List<RouteBase> routes) {
      for (final RouteBase route in routes) {
        if (route is GoRoute) {
          found.add((route, route.path));
          walk(route.routes);
        } else if (route is StatefulShellRoute) {
          for (final StatefulShellBranch branch in route.branches) {
            walk(branch.routes);
          }
        } else {
          walk(route.routes);
        }
      }
    }

    final StatefulShellRoute shell = router.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;

    for (final StatefulShellBranch branch in shell.branches) {
      walk(branch.routes);
    }

    return found;
  }

  test('every screen under a tab is pushed above the shell', () {
    final GoRouter router = buildRouter();
    final List<String> offenders = <String>[
      for (final (GoRoute route, String path) in shellRoutes(router))
        if (!tabs.contains(path) &&
            route.parentNavigatorKey != AppNavigatorKey.root)
          path,
    ];

    expect(
      offenders,
      isEmpty,
      reason: 'these keep the nav bar over them: ${offenders.join(', ')}',
    );
  });

  test('the five tab roots stay inside the shell', () {
    final GoRouter router = buildRouter();

    for (final (GoRoute route, String path) in shellRoutes(router)) {
      if (!tabs.contains(path)) continue;

      // The opposite mistake: a tab lifted onto the root navigator would lose
      // the bar entirely and there would be no way back to the other four.
      expect(
        route.parentNavigatorKey,
        isNull,
        reason: '$path was lifted out of the shell',
      );
    }
  });

  test('the shell has one branch per tab', () {
    final GoRouter router = buildRouter();
    final StatefulShellRoute shell = router.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;

    // Hard rule 13: five bottom tabs, and the list is closed.
    expect(shell.branches.length, tabs.length);
  });
}
