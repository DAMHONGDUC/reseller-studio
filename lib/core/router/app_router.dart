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
import '../../features/app_config/presentation/screens/account_blocked_screen/account_blocked_screen.dart';
import '../../features/app_config/providers.dart';
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
import '../../features/more/presentation/screens/account_screen/account_screen.dart';
import '../../features/more/presentation/screens/contact_support_screen/contact_support_screen.dart';
import '../../features/more/presentation/screens/more_screen/more_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen/notifications_screen.dart';
import '../../features/offers/presentation/screens/offers_screen/offers_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen/onboarding_screen.dart';
import '../../features/onboarding/providers.dart';
import '../../features/orders/presentation/screens/import_payouts_screen/import_payouts_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen/orders_screen.dart';
import '../../features/orders/presentation/screens/payouts_screen/payouts_screen.dart';
import '../../features/orders/presentation/screens/record_payouts_screen/record_payouts_screen.dart';
import '../../features/orders/presentation/screens/record_sale_screen/record_sale_screen.dart';
import '../../features/orders/presentation/screens/shipping_queue_screen/shipping_queue_screen.dart';
import '../../features/receipts/presentation/screens/receipts_screen/receipts_screen.dart';
import '../../features/reports/presentation/screens/books_screen/books_screen.dart';
import '../../features/reports/presentation/screens/reports_screen/reports_screen.dart';
import '../../features/search/presentation/screens/search_screen/search_screen.dart';
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
import '../../features/workspace/presentation/screens/workspaces_screen/workspaces_screen.dart';
import '../../features/workspace/providers.dart';
import '../constants/log_tag_constant.dart';
import '../widgets/app_shell.dart';
import '../widgets/splash_screen.dart';
import 'app_bottom_sheet_page.dart';
import 'app_navigator_key.dart';
import 'app_routes.dart';
import 'splash_hold.dart';

/// The app's router.
///
/// **The redirect is the whole gate, and it guards two things.** Login is
/// mandatory and there is no guest mode (plan principle 1); and every business
/// record lives under a workspace (hard rule 14), so a signed-in account with
/// none has nowhere to read or write. Rather than each screen checking either,
/// one function does:
///
/// - the config blocks this account → [AppRoutes.blocked], above everything:
///   it is decided by who is signed in, so nothing an onboarding flag or a
///   workspace says can change it;
/// - already on the splash with the loading animation owed time → stay
///   ([splashHoldProvider]). Below the block above, which cannot wait;
/// - onboarding or auth state still unknown → [AppRoutes.splash]; showing the
///   login form here would flash it at a returning user before their session
///   resolves, and showing the intro would flash it at one who finished it
///   months ago;
/// - signed out with the intro unfinished → [AppRoutes.onboarding]. It is
///   checked before login and never after it: a returning seller who signs
///   out must land on the login form, not be re-introduced to the product;
/// - signed out, anywhere at all → stay. **A guest gets the whole app**
///   (hard rule 1, `docs/rules/GUEST_MODE.md`); the two exceptions are the
///   splash, which has nothing left to wait for, and workspace setup, which
///   belongs to an account;
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
      final bool blocked = ref.read(accountBlockedProvider);
      final String location = state.matchedLocation;
      final bool onAuthRoute = _authRoutes.contains(location);

      // **Above everything, the intro included.** It is decided by the account
      // rather than by anything a workspace or a preference can change, and it
      // never reports "still loading" — an account nobody has named is not
      // blocked, so a config that has not arrived cannot be why somebody is
      // refused.
      //
      // The forced update is not here at all: it is a sheet raised over
      // whatever is on screen (`ForceUpdateGate`), so it needs no route and no
      // redirect of its own.
      if (blocked) {
        return location == AppRoutes.blocked ? null : AppRoutes.blocked;
      }

      // **The loading screen is left when it is done being watched, not when
      // the answer lands** — owner's rule, held by [splashHoldProvider]. Below
      // the block above, which is about who is signed in and cannot wait.
      if (location == AppRoutes.splash && ref.read(splashHoldProvider)) {
        return null;
      }

      if (signedIn == null || onboarding == OnboardingStatus.loading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Unreachable once the reason is gone: leaving it up would be a dead end
      // with nobody to unblock.
      if (location == AppRoutes.blocked) return AppRoutes.home;

      if (!signedIn) {
        // The intro is only ever shown to someone who is not signed in, so a
        // returning seller never sees it again whatever the flag says.
        if (onboarding == OnboardingStatus.pending) {
          return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
        }

        // **A guest gets the whole app** (hard rule 1). Their records are in
        // the local store and their business was created without asking, so
        // there is nothing here to refuse and nothing to set up.
        //
        // Three routes still bounce. **The intro is the one that matters**:
        // finishing it flips the status above to `done`, and without a bounce
        // the redirect answers "stay" — which leaves the seller on an intro
        // whose Skip and Next do nothing. The old shell got this for free
        // because `/onboarding` was outside `_previewRoutes`; unwrapping the
        // tabs dropped it. The other two name an account rather than a
        // record: workspace setup belongs to a seller who has just signed in,
        // and the splash has nothing left to wait for.
        if (location == AppRoutes.onboarding ||
            location == AppRoutes.splash ||
            location == AppRoutes.workspaceSetup) {
          return AppRoutes.home;
        }

        return null;
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
        // **No transition, and it is not a style choice.** The signed-out
        // shell renders at `/home` (hard rule 1), so signing in leaves the
        // shell for this route and comes back to it — and go_router gives
        // `StatefulShellRoute` one `GlobalKey` for the life of the router. An
        // animated page keeps the outgoing shell mounted while the next one
        // is built, which is two widgets holding one global key.
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage<void>(child: SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.blocked,
        builder: (BuildContext context, GoRouterState state) =>
            const AccountBlockedScreen(),
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
                    const HomeScreen(),
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
                    const InventoryScreen(),
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
                        ItemFormScreen(
                          initialBarcode: state.uri.queryParameters['code'],
                        ),
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
                    const OrdersScreen(),
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
                    const AnalyticsScreen(),
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
                    path: 'notifications',
                    builder: (BuildContext context, GoRouterState state) =>
                        const NotificationSettingsScreen(),
                  ),
                  GoRoute(
                    parentNavigatorKey: AppNavigatorKey.root,
                    path: 'account',
                    builder: (BuildContext context, GoRouterState state) =>
                        const AccountScreen(),
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
                              initialCode: state.uri.queryParameters['code'],
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
                            PurchasesScreen(
                              sourceId: state.uri.queryParameters['source'],
                            ),
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
                    routes: <RouteBase>[
                      GoRoute(
                        parentNavigatorKey: AppNavigatorKey.root,
                        path: 'record',
                        builder: (BuildContext context, GoRouterState state) =>
                            const RecordPayoutsScreen(),
                        routes: <RouteBase>[
                          GoRoute(
                            parentNavigatorKey: AppNavigatorKey.root,
                            path: 'import',
                            builder:
                                (BuildContext context, GoRouterState state) =>
                                    const ImportPayoutsScreen(),
                          ),
                        ],
                      ),
                    ],
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
                    path: 'businesses',
                    builder: (BuildContext context, GoRouterState state) =>
                        const WorkspacesScreen(),
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
                    path: 'support',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ContactSupportScreen(),
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
    _blocked = _listen<bool>(ref, accountBlockedProvider);
    // Inline for the same reason as onboarding: a `NotifierProvider` is not a
    // `Provider<T>`. Without it the redirect never re-runs when the hold
    // expires and the app sits on the loading screen.
    _splashHold = ref.listen<bool>(splashHoldProvider, _notifyIfChanged<bool>);
  }

  late final ProviderSubscription<bool?> _signedIn;
  late final ProviderSubscription<WorkspaceStatus> _workspace;
  late final ProviderSubscription<OnboardingStatus> _onboarding;
  late final ProviderSubscription<bool> _blocked;
  late final ProviderSubscription<bool> _splashHold;

  /// Typed on `Provider<T>` rather than the more general
  /// `ProviderListenable<T>` that `ref.listen` accepts: Riverpod 3 declares
  /// that interface but does not export it from `riverpod.dart`, so naming it
  /// here does not compile.
  ProviderSubscription<T> _listen<T>(Ref ref, Provider<T> provider) =>
      ref.listen<T>(provider, _notifyIfChanged<T>);

  /// One callback for all four, so a redirect cannot start re-running on one
  /// provider and not another.
  void _notifyIfChanged<T>(T? previous, T next) {
    if (previous != next) notifyListeners();
  }

  @override
  void dispose() {
    _signedIn.close();
    _workspace.close();
    _onboarding.close();
    _blocked.close();
    _splashHold.close();
    super.dispose();
  }
}
