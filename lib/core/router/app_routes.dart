/// Every route path and name in one place.
///
/// **Nothing types a route string at a call site.** A `context.go('/items')`
/// scattered across forty screens is a rename nobody can do safely, and a
/// typo in one is a blank screen that only shows up when a seller taps that
/// particular row.
///
/// The shape mirrors the master plan's final navigation tree (§38): five
/// shell branches, and everything else nested under whichever branch it
/// belongs to. **Nesting decides the path, not the chrome** — every route
/// under a tab names `AppNavigatorKey.root` as its parent navigator, so it is
/// pushed above the shell and carries no bottom nav. Only the five branch
/// roots keep the bar (owner's rule, `docs/rules/DESIGN_SYSTEM.md`).
final class AppRoutes {
  // --- Outside the shell: nothing here shows the tab bar. ---

  static const String splash = '/';

  /// The intro flow, shown once per install and only before sign-in.
  ///
  /// It describes the product and reads nothing — hard rule 1 is untouched,
  /// because the only way out of it is [login].
  static const String onboarding = '/onboarding';

  /// The only route that can *enter* the app unauthenticated. There is no
  /// sign-up and no password reset: sign-in is Apple or Google, and both
  /// create the account themselves on first use (owner's rule, `CLAUDE.md`
  /// hard rule 1).
  static const String login = '/login';

  /// Chosen or created after sign-in and before Home. Login is mandatory and
  /// there is no guest mode (plan principle 1), so no route below this point
  /// is reachable without a workspace.
  static const String workspaceSetup = '/workspace-setup';

  /// Creating an *additional* business, pushed from the switcher.
  ///
  /// A separate path from [workspaceSetup] on purpose: that one is a gate the
  /// redirect forces a new account through and then bounces them off again,
  /// so a seller who already has a business would be thrown straight back out
  /// of it. This one is an ordinary pushed route that pops when it is done.
  static const String workspaceCreate = '/workspace/new';

  /// Editing one business. **It names a record**, so a signed-out visitor is
  /// bounced to Home like every other detail route (hard rule 1), and it is
  /// deliberately not under Settings: the switcher opens it too, on a business
  /// the seller is not currently standing in.
  static const String workspaceDetailPath = '/workspace/:workspaceId';

  // --- Shell branch 1: Home ---

  static const String home = '/home';

  /// The inbox (§22). Under Home because that is where the bell is, and the
  /// bell is on Home because Home is the screen a seller opens to find out
  /// what happened while they were not looking.
  static const String notifications = '/home/notifications';

  // --- Shell branch 2: Inventory ---

  static const String inventory = '/inventory';
  static const String itemDetail = '/inventory/item/:itemId';

  /// Cross-listing (§13), nested under the item it publishes. Reached from
  /// the item's action sheet, never from a list — the flow starts with one
  /// item already chosen.
  static const String crossListPath = '/inventory/item/:itemId/cross-list';
  static const String addItem = '/inventory/add';
  static const String quickAdd = '/inventory/quick-add';
  static const String scanner = '/inventory/scanner';
  static const String locations = '/inventory/locations';

  // --- Shell branch 3: Orders ---

  static const String orders = '/orders';
  static const String orderDetail = '/orders/:orderId';

  /// Recording a sale from the Orders side — the second of the two ways an
  /// order is created (`lib/features/orders/CLAUDE.md`). It picks the item
  /// first and then opens the same sheet Inventory's Mark as sold does.
  ///
  /// A route rather than a sheet raised from the tab, because Quick Action on
  /// Home has to be able to start every create action the app has.
  static const String recordSale = '/orders/record-sale';
  static const String shippingQueue = '/orders/shipping-queue';
  static const String offers = '/orders/offers';
  // No `/orders/returns`: returns are opened and closed from order detail
  // (plan §16), so the screen that constant was reserved for does not exist.

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
  static const String purchaseDetail = '/more/sourcing/purchases/:purchaseId';
  static const String addPurchase = '/more/sourcing/purchases/new';
  static const String sources = '/more/sourcing/sources';
  static const String sourceDetail = '/more/sourcing/sources/:sourceId';

  /// The calculation a reseller does standing in a shop (plan §11). Its own
  /// route because it is reached mid-hunt, not from a record.
  static const String purchaseEvaluator = '/more/sourcing/evaluate';
  static const String listings = '/more/listings';
  static const String expenses = '/more/expenses';

  /// What each marketplace owes against what it paid (plan §8). Under More
  /// rather than inside Orders: it is a weekly reconciliation against a bank
  /// statement, not part of draining today's queue.
  static const String payouts = '/more/payouts';
  static const String reports = '/more/reports';
  static const String receipts = '/more/receipts';
  static const String tax = '/more/tax';
  static const String categories = '/more/categories';
  static const String marketplaces = '/more/marketplaces';
  static const String addMarketplace = '/more/marketplaces/new';
  static const String marketplaceDetailPath =
      '/more/marketplaces/:marketplaceId';
  static const String carriers = '/more/carriers';
  static const String addCarrier = '/more/carriers/new';
  static const String carrierDetailPath = '/more/carriers/:carrierId';
  static const String team = '/more/team';
  static const String settings = '/more/settings';

  /// The audit log (§23). Under More rather than under Home: it is something
  /// you go and check, not something you are told.
  static const String activity = '/more/activity';
  static const String about = '/more/about';

  /// Plan §25's Subscription block, over §27's tiers. Under More rather than
  /// nested in Settings: a blocked action pushes straight here, and a paywall
  /// two levels deep is one nobody reaches from the moment it matters.
  static const String subscription = '/more/subscription';
  static const String paywall = '/more/paywall';

  // --- Global, reachable from anywhere ---

  static const String search = '/search';

  /// Build a concrete path for a parameterised route.
  ///
  /// `AppRoutes.item('abc')` rather than `'/inventory/item/abc'`, so the one
  /// place that knows the segment layout is this file.
  static String marketplace(String marketplaceId) =>
      '/more/marketplaces/$marketplaceId';

  static String carrier(String carrierId) => '/more/carriers/$carrierId';

  static String item(String itemId) => '/inventory/item/$itemId';
  static String crossList(String itemId) =>
      '/inventory/item/$itemId/cross-list';
  static String order(String orderId) => '/orders/$orderId';
  static String workspaceDetail(String workspaceId) =>
      '/workspace/$workspaceId';
  static String source(String sourceId) => '/more/sourcing/sources/$sourceId';
  static String purchase(String purchaseId) =>
      '/more/sourcing/purchases/$purchaseId';
}
