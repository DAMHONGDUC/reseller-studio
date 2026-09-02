import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../features/activity/presentation/screens/activity_screen/activity_screen.dart';
import '../../features/analytics/presentation/screens/analytics_categories_screen/analytics_categories_screen.dart';
import '../../features/analytics/presentation/screens/analytics_inventory_screen/analytics_inventory_screen.dart';
import '../../features/analytics/presentation/screens/analytics_marketplace_screen/analytics_marketplace_screen.dart';
import '../../features/analytics/presentation/screens/analytics_profit_screen/analytics_profit_screen.dart';
import '../../features/analytics/presentation/screens/analytics_sales_screen/analytics_sales_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen/analytics_screen.dart';
import '../../features/analytics/presentation/screens/analytics_sources_screen/analytics_sources_screen.dart';
import '../../features/auth/presentation/screens/login_screen/login_screen.dart';
import '../../features/auth/providers.dart';
import '../../features/carriers/presentation/screens/carrier_detail_screen/carrier_detail_screen.dart';
import '../../features/carriers/presentation/screens/carriers_screen/carriers_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen/expenses_screen.dart';
import '../../features/home/presentation/screens/home_screen/home_screen.dart';
import '../../features/inventory/presentation/screens/categories_screen/categories_screen.dart';
import '../../features/inventory/presentation/screens/intake_session_screen/intake_session_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen/inventory_screen.dart';
import '../../features/inventory/presentation/screens/item_detail_screen/item_detail_screen.dart';
import '../../features/inventory/presentation/screens/item_form_screen/item_form_screen.dart';
import '../../features/inventory/presentation/screens/locations_screen/locations_screen.dart';
import '../../features/inventory/presentation/screens/quick_add_screen/quick_add_screen.dart';
import '../../features/inventory/presentation/screens/scanner_screen/scanner_screen.dart';
import '../../features/listings/presentation/screens/cross_list_screen/cross_list_screen.dart';
import '../../features/listings/presentation/screens/listings_screen/listings_screen.dart';
import '../../features/marketplaces/presentation/screens/marketplace_detail_screen/marketplace_detail_screen.dart';
import '../../features/marketplaces/presentation/screens/marketplaces_screen/marketplaces_screen.dart';
import '../../features/more/presentation/screens/about_screen/about_screen.dart';
import '../../features/more/presentation/screens/more_screen/more_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen/notifications_screen.dart';
import '../../features/offers/presentation/screens/offers_screen/offers_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen/onboarding_screen.dart';
import '../../features/onboarding/providers.dart';
import '../../features/orders/presentation/screens/order_detail_screen/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen/orders_screen.dart';
import '../../features/orders/presentation/screens/payouts_screen/payouts_screen.dart';
import '../../features/orders/presentation/screens/record_sale_screen/record_sale_screen.dart';
import '../../features/orders/presentation/screens/shipping_queue_screen/shipping_queue_screen.dart';
import '../../features/receipts/presentation/screens/receipts_screen/receipts_screen.dart';
import '../../features/reports/presentation/screens/books_screen/books_screen.dart';
import '../../features/reports/presentation/screens/reports_screen/reports_screen.dart';
import '../../features/search/presentation/screens/search_screen/search_screen.dart';
import '../../features/settings/presentation/screens/settings_screen/settings_screen.dart';
import '../../features/sourcing/presentation/screens/purchase_detail_screen/purchase_detail_screen.dart';
import '../../features/sourcing/presentation/screens/purchase_evaluator_screen/purchase_evaluator_screen.dart';
import '../../features/sourcing/presentation/screens/purchases_screen/purchases_screen.dart';
import '../../features/sourcing/presentation/screens/sources_screen/sources_screen.dart';
import '../../features/sourcing/presentation/screens/sourcing_screen/sourcing_screen.dart';
import '../../features/subscription/presentation/screens/paywall_screen/paywall_screen.dart';
import '../../features/subscription/presentation/screens/subscription_screen/subscription_screen.dart';
import '../../features/tax/presentation/screens/tax_screen/tax_screen.dart';
import '../../features/workspace/presentation/screens/team_screen/team_screen.dart';
import '../../features/workspace/presentation/screens/workspace_detail_screen/workspace_detail_screen.dart';
import '../../features/workspace/presentation/screens/workspace_setup_screen/workspace_setup_screen.dart';
import '../../features/workspace/providers.dart';
import '../constants/log_tag_constant.dart';
import '../extensions/context_extensions.dart';
import '../widgets/app_shell.dart';
import '../widgets/signed_out_view.dart';
import '../widgets/splash_screen.dart';
import 'app_bottom_sheet_page.dart';
import 'app_navigator_key.dart';
import 'app_routes.dart';

/// The app's router.
///
/// **The redirect is the whole gate, and it guards two things.** Login is
/// mandatory and there is no guest mode (plan principle 1); and every business
/// record lives under a workspace (hard rule 14), so a signed-in account with
/// none has nowhere to read or write. Rather than each screen checking either,
/// one function does:
///
/// - onboarding or auth state still unknown → [AppRoutes.splash]; showing the
///   login form here would flash it at a returning user before their session
///   resolves, and showing the intro would flash it at one who finished it
///   months ago;
/// - signed out with the intro unfinished → [AppRoutes.onboarding]. It is
///   checked before login and never after it: a returning seller who signs
///   out must land on the login form, not be re-introduced to the product;
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
    navigatorKey: AppNavigatorKey.root,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final bool? signedIn = ref.read(isSignedInProvider);
      final OnboardingStatus onboarding = ref.read(onboardingStatusProvider);
      final String location = state.matchedLocation;
      final bool onAuthRoute = _authRoutes.contains(location);

      if (signedIn == null || onboarding == OnboardingStatus.loading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (!signedIn) {
        // The intro is only ever shown to someone who is not signed in, so a
        // returning seller never sees it again whatever the flag says.
        if (onboarding == OnboardingStatus.pending) {
          return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
        }

        // Owner's rule: the five tabs render before sign-in, empty. The gate
        // moved from the route to the action — see `NavigationUtils`. What is
        // still refused is anything that needs a workspace to mean anything.
        return _previewRoutes.contains(location) ? null : AppRoutes.home;
      }

      final WorkspaceStatus workspace = ref.read(workspaceStatusProvider);

      if (workspace == WorkspaceStatus.loading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (workspace == WorkspaceStatus.none) {
        return location == AppRoutes.workspaceSetup
            ? null
            : AppRoutes.workspaceSetup;
      }

      // `workspaceCreate` is absent from this list on purpose: it is a pushed
      // route a seller who already has a business opens deliberately, so
      // bouncing them off it is exactly the bug the separate path avoids.
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
        path: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.workspaceCreate,
        builder: (BuildContext context, GoRouterState state) =>
            const WorkspaceSetupScreen(isAdditional: true),
      ),
      GoRoute(
        path: AppRoutes.workspaceSetup,
        builder: (BuildContext context, GoRouterState state) =>
            const WorkspaceSetupScreen(),
      ),
      // After `workspaceCreate` on purpose: go_router matches in declaration
      // order, and `/workspace/new` would otherwise be read as an id.
      GoRoute(
        path: AppRoutes.workspaceDetailPath,
        builder: (BuildContext context, GoRouterState state) =>
            WorkspaceDetailScreen(
              workspaceId: state.pathParameters['workspaceId']!,
            ),
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
                    AuthedTab(
                      title: context.l10n.navHome,
                      child: const HomeScreen(),
                    ),
                routes: <RouteBase>[
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'notifications',
                    builder: (BuildContext context, GoRouterState state) =>
                        const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.inventory,
                builder: (BuildContext context, GoRouterState state) =>
                    AuthedTab(
                      title: context.l10n.navInventory,
                      child: const InventoryScreen(),
                    ),
                routes: <RouteBase>[
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'quick-add',
                    builder: (BuildContext context, GoRouterState state) =>
                        const QuickAddScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'intake',
                    builder: (BuildContext context, GoRouterState state) =>
                        const IntakeSessionScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'add',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ItemFormScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'scanner',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ScannerScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'locations',
                    builder: (BuildContext context, GoRouterState state) =>
                        const LocationsScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'item/:itemId',
                    builder: (BuildContext context, GoRouterState state) =>
                        ItemDetailScreen(
                          // The path parameter is the screen's only input, so
                          // a deep link into an item works with just an id.
                          itemId: state.pathParameters['itemId']!,
                        ),
                    routes: <RouteBase>[
                      GoRoute(
                        parentNavigatorKey: AppNavigatorKey.root,
                        path: 'cross-list',
                        builder: (BuildContext context, GoRouterState state) =>
                            CrossListScreen(
                              itemId: state.pathParameters['itemId']!,
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
                    AuthedTab(
                      title: context.l10n.navOrders,
                      child: const OrdersScreen(),
                    ),
                routes: <RouteBase>[
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'shipping-queue',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ShippingQueueScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'offers',
                    builder: (BuildContext context, GoRouterState state) =>
                        const OffersScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'record-sale',
                    builder: (BuildContext context, GoRouterState state) =>
                        const RecordSaleScreen(),
                  ),
                  // Last among the order sub-routes on purpose: a literal
                  // segment declared after `:orderId` would be swallowed by
                  // the parameter, so every fixed path must come first.
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
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
                    AuthedTab(
                      title: context.l10n.navAnalytics,
                      child: const AnalyticsScreen(),
                    ),
                routes: <RouteBase>[
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'sales',
                    builder: (BuildContext context, GoRouterState state) =>
                        const AnalyticsSalesScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'profit',
                    builder: (BuildContext context, GoRouterState state) =>
                        const AnalyticsProfitScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'inventory',
                    builder: (BuildContext context, GoRouterState state) =>
                        const AnalyticsInventoryScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'marketplace',
                    builder: (BuildContext context, GoRouterState state) =>
                        const AnalyticsMarketplaceScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'categories',
                    builder: (BuildContext context, GoRouterState state) =>
                        const AnalyticsCategoriesScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'sources',
                    builder: (BuildContext context, GoRouterState state) =>
                        const AnalyticsSourcesScreen(),
                  ),
                ],
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
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'books',
                    builder: (BuildContext context, GoRouterState state) =>
                        const BooksScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'settings',
                    builder: (BuildContext context, GoRouterState state) =>
                        const SettingsScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        parentNavigatorKey: AppNavigatorKey.root,
                        path: 'notifications',
                        builder: (BuildContext context, GoRouterState state) =>
                            const NotificationSettingsScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'sourcing',
                    builder: (BuildContext context, GoRouterState state) =>
                        const SourcingScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        parentNavigatorKey: AppNavigatorKey.root,
                        path: 'evaluate',
                        builder: (BuildContext context, GoRouterState state) =>
                            PurchaseEvaluatorScreen(
                              initialCode:
                                  state.uri.queryParameters['code'],
                            ),
                      ),
                      GoRoute(
                        parentNavigatorKey: AppNavigatorKey.root,
                        path: 'sources',
                        builder: (BuildContext context, GoRouterState state) =>
                            const SourcesScreen(),
                      ),
                      GoRoute(
                        parentNavigatorKey: AppNavigatorKey.root,
                        path: 'purchases',
                        builder: (BuildContext context, GoRouterState state) =>
                            const PurchasesScreen(),
                        routes: <RouteBase>[
                          GoRoute(
                            parentNavigatorKey: AppNavigatorKey.root,
                            path: ':purchaseId',
                            builder:
                                (BuildContext context, GoRouterState state) =>
                                    PurchaseDetailScreen(
                                      purchaseId:
                                          state.pathParameters['purchaseId']!,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'listings',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ListingsScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'expenses',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ExpensesScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'payouts',
                    builder: (BuildContext context, GoRouterState state) =>
                        const PayoutsScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'reports',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ReportsScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'receipts',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ReceiptsScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'categories',
                    builder: (BuildContext context, GoRouterState state) =>
                        const CategoriesScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'marketplaces',
                    builder: (BuildContext context, GoRouterState state) =>
                        const MarketplacesScreen(),
                    routes: <RouteBase>[
                      // Before the `:marketplaceId` route, or 'new' matches it
                      // and the form opens looking for a record called "new".
                      GoRoute(
                        parentNavigatorKey: AppNavigatorKey.root,
                        path: 'new',
                        builder: (BuildContext context, GoRouterState state) =>
                            const MarketplaceDetailScreen(),
                      ),
                      GoRoute(
                        parentNavigatorKey: AppNavigatorKey.root,
                        path: ':marketplaceId',
                        builder: (BuildContext context, GoRouterState state) =>
                            MarketplaceDetailScreen(
                              marketplaceId:
                                  state.pathParameters['marketplaceId'],
                            ),
                      ),
                    ],
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'carriers',
                    builder: (BuildContext context, GoRouterState state) =>
                        const CarriersScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        parentNavigatorKey: AppNavigatorKey.root,
                        path: 'new',
                        builder: (BuildContext context, GoRouterState state) =>
                            const CarrierDetailScreen(),
                      ),
                      GoRoute(
                        parentNavigatorKey: AppNavigatorKey.root,
                        path: ':carrierId',
                        builder: (BuildContext context, GoRouterState state) =>
                            CarrierDetailScreen(
                              carrierId: state.pathParameters['carrierId'],
                            ),
                      ),
                    ],
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'team',
                    builder: (BuildContext context, GoRouterState state) =>
                        const TeamScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'activity',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ActivityScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'about',
                    builder: (BuildContext context, GoRouterState state) =>
                        const AboutScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'subscription',
                    builder: (BuildContext context, GoRouterState state) =>
                        const SubscriptionScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'paywall',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        AppBottomSheetPage<void>(
                          key: state.pageKey,
                          name: state.name,
                          builder: (BuildContext context) =>
                              const PaywallScreen(),
                        ),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'tax',
                    builder: (BuildContext context, GoRouterState state) =>
                        const TaxScreen(),
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
      SdLogger.error(
        LogTagConstant.navigation,
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
/// Two, and that is the whole of it: the intro, and the sign-in gate itself.
/// There is no sign-up screen and no password reset to reach — sign-in is
/// Apple or Google, and both create the account themselves (owner's rule).
///
/// Read by the signed-in branch, which uses it to bounce an authenticated
/// seller off either one to Home. Which of the two a signed-*out* user belongs
/// on is decided above, by `OnboardingStatus`.
const Set<String> _authRoutes = <String>{AppRoutes.onboarding, AppRoutes.login};

/// What a signed-out visitor may sit on — the five tabs, empty, plus the gate
/// itself (owner's rule; `CLAUDE.md` hard rule 1).
///
/// **Deliberately the five tab roots and nothing below them.** A detail route
/// names a record that a signed-out visitor cannot have, and workspace setup
/// needs an account to attach the business to; both are bounced to Home rather
/// than rendered against nothing. Everything reachable *from* a tab is an
/// action, and actions go through `NavigationUtils.requireSignIn`.
const Set<String> _previewRoutes = <String>{
  AppRoutes.login,
  AppRoutes.home,
  AppRoutes.inventory,
  AppRoutes.orders,
  AppRoutes.analytics,
  AppRoutes.more,
  // Settings is the one screen below a tab that works without an account:
  // theme and language are device preferences, not business data.
  AppRoutes.settings,
};

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
    // Declared inline rather than through [_listen] because this one is a
    // `NotifierProvider`, which is not a `Provider<T>` — see that method.
    _onboarding = ref.listen<OnboardingStatus>(
      onboardingStatusProvider,
      _notifyIfChanged<OnboardingStatus>,
    );
  }

  late final ProviderSubscription<bool?> _signedIn;
  late final ProviderSubscription<WorkspaceStatus> _workspace;
  late final ProviderSubscription<OnboardingStatus> _onboarding;

  /// Typed on `Provider<T>` rather than the more general
  /// `ProviderListenable<T>` that `ref.listen` accepts: Riverpod 3 declares
  /// that interface but does not export it from `riverpod.dart`, so naming it
  /// here does not compile.
  ProviderSubscription<T> _listen<T>(Ref ref, Provider<T> provider) =>
      ref.listen<T>(provider, _notifyIfChanged<T>);

  /// One callback for all three, so a redirect cannot start re-running on one
  /// provider and not another.
  void _notifyIfChanged<T>(T? previous, T next) {
    if (previous != next) notifyListeners();
  }

  @override
  void dispose() {
    _signedIn.close();
    _workspace.close();
    _onboarding.close();
    super.dispose();
  }
}
