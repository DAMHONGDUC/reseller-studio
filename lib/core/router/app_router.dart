import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/analytics/presentation/screens/analytics_screen/analytics_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/providers.dart';
import '../../features/home/presentation/screens/home_screen/home_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import '../../features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import '../../features/more/presentation/screens/more_screen/more_screen.dart';
import '../../features/orders/presentation/screens/orders_screen/orders_screen.dart';
import '../../features/settings/presentation/screens/settings_screen/settings_screen.dart';
import '../logging/app_logger.dart';
import '../widgets/app_shell.dart';
import '../widgets/splash_screen.dart';
import 'app_routes.dart';

/// The app's router.
///
/// **The redirect is the whole authentication gate.** Login is mandatory and
/// there is no guest mode (plan principle 1), so rather than each screen
/// checking whether anyone is signed in, one function does:
///
/// - auth state still unknown → [AppRoutes.splash]; showing the login form
///   here would flash it at a returning user before their session resolves;
/// - signed out, anywhere but an auth route → [AppRoutes.login];
/// - signed in, sitting on an auth route → [AppRoutes.home].
///
/// Returning `null` means "stay put", which is the answer for every other
/// combination — a redirect that fired on every navigation would fight the
/// user's own taps.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final bool? signedIn = ref.read(isSignedInProvider);
      final String location = state.matchedLocation;
      final bool onAuthRoute = _authRoutes.contains(location);

      if (signedIn == null) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (!signedIn) return onAuthRoute ? null : AppRoutes.login;

      if (onAuthRoute || location == AppRoutes.splash) return AppRoutes.home;

      return null;
    },
    // The redirect reads auth state, so the router has to be told when that
    // state changes — go_router does not watch providers itself, and without
    // this a sign-out leaves the user sitting on Inventory.
    refreshListenable: _ProviderRefreshListenable<bool?>(
      ref,
      isSignedInProvider,
    ),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell shell,
            ) => AppShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.inventory,
                builder: (BuildContext context, GoRouterState state) =>
                    const InventoryScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'item/:itemId',
                    builder: (BuildContext context, GoRouterState state) =>
                        ItemDetailScreen(
                          // The path parameter is the screen's only input, so
                          // a deep link into an item works with just an id.
                          itemId: state.pathParameters['itemId']!,
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.orders,
                builder: (BuildContext context, GoRouterState state) =>
                    const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.analytics,
                builder: (BuildContext context, GoRouterState state) =>
                    const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.more,
                builder: (BuildContext context, GoRouterState state) =>
                    const MoreScreen(),
                // Nested, not a sibling: a detail pushed inside its branch
                // keeps the tab bar visible and keeps its own back stack, so
                // a seller three screens deep in More can check an order and
                // come back to where they were.
                routes: <RouteBase>[
                  GoRoute(
                    path: 'settings',
                    builder: (BuildContext context, GoRouterState state) =>
                        const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    onException:
        (BuildContext context, GoRouterState state, GoRouter router) {
          // A route that does not exist is a bug in the app, not something to
          // show the user a stack trace about. Log it and put them somewhere
          // real. Plan §31: never expose a raw technical error.
          AppLogger.error(
            'Navigate to unknown route',
            error: StateError('No route for ${state.uri}'),
          );
          router.go(AppRoutes.home);
        },
  );

  ref.onDispose(router.dispose);

  return router;
});

/// The routes a signed-out user is allowed to sit on.
const Set<String> _authRoutes = <String>{
  AppRoutes.login,
  AppRoutes.signUp,
  AppRoutes.forgotPassword,
};

/// Bridges a Riverpod provider to go_router's `refreshListenable`.
///
/// go_router re-runs its redirect when this notifies. It notifies only when
/// the value actually changes, so a rebuild that produces the same auth state
/// does not re-run every redirect in the stack.
///
/// Typed on `Provider<T>` rather than the more general `ProviderListenable<T>`
/// that `ref.listen` accepts: Riverpod 3 declares that interface but does not
/// export it from `riverpod.dart`, so naming it here does not compile. Every
/// provider this bridges is a plain `Provider` anyway.
class _ProviderRefreshListenable<T> extends ChangeNotifier {
  _ProviderRefreshListenable(Ref ref, Provider<T> provider) {
    _subscription = ref.listen<T>(
      provider,
      (T? previous, T next) {
        if (previous != next) notifyListeners();
      },
    );
  }

  late final ProviderSubscription<T> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
