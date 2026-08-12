import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/analytics/presentation/screens/analytics_screen/analytics_screen.dart';
import '../../features/auth/presentation/screens/login_screen/login_screen.dart';
import '../../features/auth/providers.dart';
import '../../features/expenses/presentation/screens/expenses_screen/expenses_screen.dart';
import '../../features/home/presentation/screens/home_screen/home_screen.dart';
import '../../features/inventory/presentation/screens/categories_screen/categories_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import '../../features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import '../../features/inventory/presentation/screens/item_form_screen/item_form_screen.dart';
import '../../features/inventory/presentation/screens/locations_screen/locations_screen.dart';
import '../../features/inventory/presentation/screens/quick_add_screen/quick_add_screen.dart';
import '../../features/inventory/presentation/screens/scanner_screen/scanner_screen.dart';
import '../../features/listings/presentation/screens/listings_screen/listings_screen.dart';
import '../../features/marketplaces/presentation/screens/marketplaces_screen/marketplaces_screen.dart';
import '../../features/more/presentation/screens/more_screen/more_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen/orders_screen.dart';
import '../../features/orders/presentation/screens/shipping_queue_screen/shipping_queue_screen.dart';
import '../../features/reports/presentation/screens/reports_screen/reports_screen.dart';
import '../../features/search/presentation/screens/search_screen/search_screen.dart';
import '../../features/settings/presentation/screens/settings_screen/settings_screen.dart';
import '../../features/sourcing/presentation/screens/purchase_detail_screen/purchase_detail_screen.dart';
import '../../features/sourcing/presentation/screens/purchase_evaluator_screen/purchase_evaluator_screen.dart';
import '../../features/sourcing/presentation/screens/purchases_screen/purchases_screen.dart';
import '../../features/sourcing/presentation/screens/sources_screen/sources_screen.dart';
import '../../features/sourcing/presentation/screens/sourcing_screen/sourcing_screen.dart';
import '../../features/workspace/presentation/screens/team_screen/team_screen.dart';
import '../../features/workspace/presentation/screens/workspace_setup_screen/workspace_setup_screen.dart';
import '../../features/workspace/providers.dart';
import '../logging/app_logger.dart';
import '../widgets/app_shell.dart';
import '../widgets/splash_screen.dart';
import 'app_routes.dart';

/// The app's router.
///
/// **The redirect is the whole gate, and it guards two things.** Login is
/// mandatory and there is no guest mode (plan principle 1); and every business
/// record lives under a workspace (hard rule 14), so a signed-in account with
/// none has nowhere to read or write. Rather than each screen checking either,
/// one function does:
///
/// - auth state still unknown → [AppRoutes.splash]; showing the login form
///   here would flash it at a returning user before their session resolves;
/// - signed out, anywhere but an auth route → [AppRoutes.login];
/// - signed in, workspace still loading → [AppRoutes.splash], for the same
///   reason: asking a returning seller to create a second business every time
///   they open the app is the most visible way to get this wrong;
/// - signed in with no workspace → [AppRoutes.workspaceSetup];
/// - signed in and set up, sitting on an auth or setup route →
///   [AppRoutes.home].
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

      final WorkspaceStatus workspace = ref.read(workspaceStatusProvider);

      if (workspace == WorkspaceStatus.loading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (workspace == WorkspaceStatus.none) {
        return location == AppRoutes.workspaceSetup
            ? null
            : AppRoutes.workspaceSetup;
      }

      if (onAuthRoute ||
          location == AppRoutes.splash ||
          location == AppRoutes.workspaceSetup) {
        return AppRoutes.home;
      }

      return null;
    },
    // The redirect reads auth state and workspace state, so the router has to
    // be told when either changes — go_router does not watch providers
    // itself, and without this a sign-out leaves the user sitting on
    // Inventory and a finished setup never leaves the form.
    refreshListenable: _RouterRefreshListenable(ref),
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
      GoRoute(
        path: AppRoutes.workspaceSetup,
        builder: (BuildContext context, GoRouterState state) =>
            const WorkspaceSetupScreen(),
      ),
      // Outside the shell: search covers the whole app rather than one tab,
      // and it is reached from every one of them.
      GoRoute(
        path: AppRoutes.search,
        builder: (BuildContext context, GoRouterState state) =>
            const SearchScreen(),
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
                    path: 'quick-add',
                    builder: (BuildContext context, GoRouterState state) =>
                        const QuickAddScreen(),
                  ),
                  GoRoute(
                    path: 'add',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ItemFormScreen(),
                  ),
                  GoRoute(
                    path: 'scanner',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ScannerScreen(),
                  ),
                  GoRoute(
                    path: 'locations',
                    builder: (BuildContext context, GoRouterState state) =>
                        const LocationsScreen(),
                  ),
                  GoRoute(
                    path: 'item/:itemId',
                    builder: (BuildContext context, GoRouterState state) =>
                        ItemDetailScreen(
                          // The path parameter is the screen's only input, so
                          // a deep link into an item works with just an id.
                          itemId: state.pathParameters['itemId']!,
                        ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'edit',
                        builder: (BuildContext context, GoRouterState state) =>
                            ItemFormScreen(
                              itemId: state.pathParameters['itemId'],
                            ),
                      ),
                    ],
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
                routes: <RouteBase>[
                  GoRoute(
                    path: 'shipping-queue',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ShippingQueueScreen(),
                  ),
                  // Last among the order sub-routes on purpose: a literal
                  // segment declared after `:orderId` would be swallowed by
                  // the parameter, so every fixed path must come first.
                  GoRoute(
                    path: ':orderId',
                    builder: (BuildContext context, GoRouterState state) =>
                        OrderDetailScreen(
                          orderId: state.pathParameters['orderId']!,
                        ),
                  ),
                ],
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
                  GoRoute(
                    path: 'sourcing',
                    builder: (BuildContext context, GoRouterState state) =>
                        const SourcingScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'evaluate',
                        builder: (BuildContext context, GoRouterState state) =>
                            const PurchaseEvaluatorScreen(),
                      ),
                      GoRoute(
                        path: 'sources',
                        builder: (BuildContext context, GoRouterState state) =>
                            const SourcesScreen(),
                      ),
                      GoRoute(
                        path: 'purchases',
                        builder: (BuildContext context, GoRouterState state) =>
                            const PurchasesScreen(),
                        routes: <RouteBase>[
                          GoRoute(
                            path: ':purchaseId',
                            builder:
                                (
                                  BuildContext context,
                                  GoRouterState state,
                                ) => PurchaseDetailScreen(
                                  purchaseId:
                                      state.pathParameters['purchaseId']!,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'listings',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ListingsScreen(),
                  ),
                  GoRoute(
                    path: 'expenses',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ExpensesScreen(),
                  ),
                  GoRoute(
                    path: 'reports',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ReportsScreen(),
                  ),
                  GoRoute(
                    path: 'categories',
                    builder: (BuildContext context, GoRouterState state) =>
                        const CategoriesScreen(),
                  ),
                  GoRoute(
                    path: 'marketplaces',
                    builder: (BuildContext context, GoRouterState state) =>
                        const MarketplacesScreen(),
                  ),
                  GoRoute(
                    path: 'team',
                    builder: (BuildContext context, GoRouterState state) =>
                        const TeamScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    onException: (BuildContext context, GoRouterState state, GoRouter router) {
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
///
/// One, and that is the whole of it: sign-in is Apple or Google, so there is
/// no sign-up screen and no password reset to reach (owner's rule).
const Set<String> _authRoutes = <String>{AppRoutes.login};

/// Bridges the two providers the redirect reads to go_router's
/// `refreshListenable`.
///
/// go_router re-runs its redirect when this notifies. It notifies only when a
/// value actually changes, so a rebuild that produces the same auth state
/// does not re-run every redirect in the stack.
///
/// Both subscriptions live here rather than in a `Listenable.merge` of two
/// objects: merge does not dispose what it merges, and a
/// `ProviderSubscription` that outlives the router keeps the whole provider
/// graph alive.
class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(Ref ref) {
    _signedIn = _listen<bool?>(ref, isSignedInProvider);
    _workspace = _listen<WorkspaceStatus>(ref, workspaceStatusProvider);
  }

  late final ProviderSubscription<bool?> _signedIn;
  late final ProviderSubscription<WorkspaceStatus> _workspace;

  /// Typed on `Provider<T>` rather than the more general
  /// `ProviderListenable<T>` that `ref.listen` accepts: Riverpod 3 declares
  /// that interface but does not export it from `riverpod.dart`, so naming it
  /// here does not compile. Both providers are plain `Provider`s anyway.
  ProviderSubscription<T> _listen<T>(Ref ref, Provider<T> provider) =>
      ref.listen<T>(provider, (T? previous, T next) {
        if (previous != next) notifyListeners();
      });

  @override
  void dispose() {
    _signedIn.close();
    _workspace.close();
    super.dispose();
  }
}
