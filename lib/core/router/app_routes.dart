/// Every route path and name in one place.
///
/// **Nothing types a route string at a call site.** A `context.go('/items')`
/// scattered across forty screens is a rename nobody can do safely, and a
/// typo in one is a blank screen that only shows up when a seller taps that
/// particular row.
///
/// The shape mirrors the master plan's final navigation tree (§38): five
/// shell branches, and everything else pushed on top of whichever branch it
/// belongs to. A detail screen is a child of its tab, not a sibling — that is
/// what keeps the tab bar visible and the back stack per-tab.
abstract final class AppRoutes {
  // --- Outside the shell: nothing here shows the tab bar. ---

  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';

  /// Chosen or created after sign-in and before Home. Login is mandatory and
  /// there is no guest mode (plan principle 1), so no route below this point
  /// is reachable without a workspace.
  static const String workspaceSetup = '/workspace-setup';

  // --- Shell branch 1: Home ---

  static const String home = '/home';
  static const String notifications = '/home/notifications';
  static const String activity = '/home/activity';

  // --- Shell branch 2: Inventory ---

  static const String inventory = '/inventory';
  static const String itemDetail = '/inventory/item/:itemId';
  static const String addItem = '/inventory/add';
  static const String quickAdd = '/inventory/quick-add';
  static const String scanner = '/inventory/scanner';
  static const String locations = '/inventory/locations';

  // --- Shell branch 3: Orders ---

  static const String orders = '/orders';
  static const String orderDetail = '/orders/:orderId';
  static const String shippingQueue = '/orders/shipping-queue';
  static const String offers = '/orders/offers';
  static const String returns = '/orders/returns';

  // --- Shell branch 4: Analytics ---

  static const String analytics = '/analytics';
  static const String analyticsSales = '/analytics/sales';
  static const String analyticsProfit = '/analytics/profit';
  static const String analyticsInventory = '/analytics/inventory';
  static const String analyticsMarketplace = '/analytics/marketplace';
  static const String analyticsCategories = '/analytics/categories';
  static const String analyticsSources = '/analytics/sources';

  // --- Shell branch 5: More ---

  static const String more = '/more';
  static const String sourcing = '/more/sourcing';
  static const String purchases = '/more/sourcing/purchases';
  static const String sources = '/more/sourcing/sources';
  static const String listings = '/more/listings';
  static const String expenses = '/more/expenses';
  static const String reports = '/more/reports';
  static const String receipts = '/more/receipts';
  static const String categories = '/more/categories';
  static const String marketplaces = '/more/marketplaces';
  static const String team = '/more/team';
  static const String settings = '/more/settings';

  // --- Global, reachable from anywhere ---

  static const String search = '/search';

  /// Build a concrete path for a parameterised route.
  ///
  /// `AppRoutes.item('abc')` rather than `'/inventory/item/abc'`, so the one
  /// place that knows the segment layout is this file.
  static String item(String itemId) => '/inventory/item/$itemId';
  static String order(String orderId) => '/orders/$orderId';
}
