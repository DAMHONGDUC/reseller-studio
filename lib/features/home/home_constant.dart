import 'package:flutter/widgets.dart';

import '../../core/constants/app_icon_constant.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/router/app_routes.dart';
import 'domain/enums/getting_started_step.dart';

/// Numbers the Home feature is tuned by, kept off the widgets that read them.
///
/// A row count is configuration about Recent Activity, not part of what the
/// widget *is* — so it does not live on the widget. See the constants rule in
/// `CLAUDE.md`.
final class HomeConstant {
  /// Three rows. Enough to answer "what happened since I last looked" without
  /// turning Home into a second Orders screen.
  static const int recentActivityMaxRows = 3;
}

/// **The three buttons in Home's shortcut row, in order** — owner's rule.
///
/// The first is the filled one; what each does is in
/// `lib/features/home/CLAUDE.md`. **Three, and the list is closed.** A fourth
/// makes the row a launcher.
enum HomeShortcut {
  /// Opens `AddStockSheet`: Quick add, Scan, Take stock in.
  addStock,

  /// Scrolls Home to its Quick Action section.
  quickAction,

  /// Pushes the record-sale flow, as its Quick Action row does.
  recordSale,
}

/// How a shortcut reads and looks lives on the enum — owner's rule.
extension HomeShortcutDisplay on HomeShortcut {
  String label(BuildContext context) => switch (this) {
    HomeShortcut.addStock => context.l10n.inventoryAddTitle,
    HomeShortcut.quickAction => context.l10n.homeQuickAction,
    HomeShortcut.recordSale => QuickActionLabel.of(
      context,
      QuickActionKind.recordSale,
    ),
  };

  IconData get icon => switch (this) {
    HomeShortcut.addStock => AppIconConstant.addBox,
    HomeShortcut.quickAction => AppIconConstant.bolt,
    HomeShortcut.recordSale => AppIconConstant.payments,
  };
}

/// One create action, as Quick Action offers it.
///
/// **The label is not here.** A label is a user-facing string (hard rule 7),
/// so the row carries a [kind] and `QuickActionLabel` turns it into words —
/// which is also what keeps the list below `const`. The same shape
/// `MoreDestination` has, for the same reason.
class QuickAction {
  const QuickAction({
    required this.kind,
    required this.icon,
    required this.route,
    this.open = QuickActionOpen.push,
  });

  final QuickActionKind kind;
  final IconData icon;

  final String route;

  /// **How the row opens, as a property of the row.** An enum rather than a
  /// bool: a third behaviour picked by flags at the call site is how the
  /// fourth one ends up implemented twice.
  final QuickActionOpen open;
}

/// What tapping a Quick Action row does.
enum QuickActionOpen {
  /// The common case: a screen above Home that comes back here.
  push,

  /// A shell branch root. Pushing one over Home leaves the seller on the wrong
  /// tab with a back button they should not have.
  goTab,
}

/// Every create action in the app.
enum QuickActionKind {
  quickAddItem,
  intakeSession,
  addItem,
  scan,
  recordSale,
  recordPurchase,
  addExpense,
  addSource,
  addCategory,
  addLocation,
  addWorkspace,
  addMarketplace,
  addCarrier,
  inviteTeammate,
  analytics,
  about,
}

class QuickActionSection {
  const QuickActionSection({required this.kind, required this.actions});

  final QuickActionSectionKind kind;
  final List<QuickAction> actions;
}

enum QuickActionSectionKind { inventory, operations, business, app }

final class QuickActionSectionLabel {
  static String of(BuildContext context, QuickActionSectionKind kind) =>
      switch (kind) {
        QuickActionSectionKind.inventory => context.l10n.navInventory,
        QuickActionSectionKind.operations => context.l10n.moreSectionOperations,
        QuickActionSectionKind.business => context.l10n.moreSectionBusiness,
        QuickActionSectionKind.app => context.l10n.settingsApp,
      };
}

/// **Everything this app can create, and — last — the page explaining how
/// it all connects.**
///
/// Quick Action exists because the create actions are scattered by design —
/// each lives on the screen that owns the records it makes, behind that
/// screen's own `SdFabV3` (owner's rule). That is right for a seller already
/// on the screen and wrong for one who opened the app to add something: it is
/// three taps to record an expense from Home.
///
/// **Two rows do not create something, and they ride at the end** — owner's
/// rule: About last, Analytics just above it. About lives two levels deep
/// under Settings, so this is what keeps it findable; putting both at the end
/// is what stops a seller scanning for "add" from stepping over them. Nothing
/// else non-create joins them without the same decision.
///
/// **Adding a create action anywhere means adding it here.**
/// `test/features/home/quick_access_test.dart` fails when a screen grows an
/// `AppAddFabScaffold` this list does not know about, so the two cannot
/// drift.
final class QuickActionConstant {
  static const List<QuickActionSection> sections = <QuickActionSection>[
    QuickActionSection(
      kind: QuickActionSectionKind.inventory,
      actions: <QuickAction>[
        QuickAction(
          kind: QuickActionKind.quickAddItem,
          icon: AppIconConstant.bolt,
          route: AppRoutes.quickAdd,
        ),
        QuickAction(
          kind: QuickActionKind.intakeSession,
          icon: AppIconConstant.storefront,
          route: AppRoutes.intake,
        ),
        QuickAction(
          kind: QuickActionKind.scan,
          icon: AppIconConstant.barcodeScanner,
          route: AppRoutes.scanner,
        ),
        QuickAction(
          kind: QuickActionKind.addItem,
          icon: AppIconConstant.addBox,
          route: AppRoutes.addItem,
        ),
        QuickAction(
          kind: QuickActionKind.addCategory,
          icon: AppIconConstant.category,
          route: AppRoutes.categories,
        ),
        QuickAction(
          kind: QuickActionKind.addLocation,
          icon: AppIconConstant.shelves,
          route: AppRoutes.locations,
        ),
      ],
    ),
    QuickActionSection(
      kind: QuickActionSectionKind.operations,
      actions: <QuickAction>[
        QuickAction(
          kind: QuickActionKind.recordSale,
          icon: AppIconConstant.payments,
          route: AppRoutes.recordSale,
        ),
        QuickAction(
          kind: QuickActionKind.recordPurchase,
          icon: AppIconConstant.shoppingBag,
          route: AppRoutes.addPurchase,
        ),
        QuickAction(
          kind: QuickActionKind.addExpense,
          icon: AppIconConstant.receipt,
          route: AppRoutes.expenses,
        ),
        QuickAction(
          kind: QuickActionKind.addSource,
          icon: AppIconConstant.storefront,
          route: AppRoutes.sources,
        ),
      ],
    ),
    QuickActionSection(
      kind: QuickActionSectionKind.business,
      actions: <QuickAction>[
        QuickAction(
          kind: QuickActionKind.addWorkspace,
          icon: AppIconConstant.storefront,
          route: AppRoutes.workspaces,
        ),
        QuickAction(
          kind: QuickActionKind.addMarketplace,
          icon: AppIconConstant.hub,
          route: AppRoutes.marketplaces,
        ),
        QuickAction(
          kind: QuickActionKind.addCarrier,
          icon: AppIconConstant.localShipping,
          route: AppRoutes.carriers,
        ),
        QuickAction(
          kind: QuickActionKind.inviteTeammate,
          icon: AppIconConstant.groupAdd,
          route: AppRoutes.team,
        ),
      ],
    ),
    QuickActionSection(
      kind: QuickActionSectionKind.app,
      actions: <QuickAction>[
        QuickAction(
          kind: QuickActionKind.analytics,
          icon: AppIconConstant.barChart,
          route: AppRoutes.analytics,
          open: QuickActionOpen.goTab,
        ),
        QuickAction(
          kind: QuickActionKind.about,
          icon: AppIconConstant.info,
          route: AppRoutes.about,
        ),
      ],
    ),
  ];

  static List<QuickAction> get actions => sections
      .expand((QuickActionSection section) => section.actions)
      .toList(growable: false);
}

/// The words for a Quick Access tile.
final class QuickActionLabel {
  static String of(BuildContext context, QuickActionKind kind) =>
      switch (kind) {
        QuickActionKind.quickAddItem => context.l10n.quickAddTitle,
        QuickActionKind.intakeSession => context.l10n.quickActionIntakeSession,
        QuickActionKind.addItem => context.l10n.inventoryAddItem,
        QuickActionKind.scan => context.l10n.inventoryScan,
        QuickActionKind.recordSale => context.l10n.recordSaleTitle,
        QuickActionKind.recordPurchase => context.l10n.homeQuickRecordPurchase,
        QuickActionKind.addExpense => context.l10n.homeQuickAddExpense,
        QuickActionKind.addSource => context.l10n.homeQuickAddSource,
        QuickActionKind.addCategory => context.l10n.categoryAdd,
        QuickActionKind.addLocation => context.l10n.locationAdd,
        QuickActionKind.addWorkspace => context.l10n.workspaceAddTitle,
        QuickActionKind.addMarketplace => context.l10n.marketplaceAdd,
        QuickActionKind.addCarrier => context.l10n.carrierAdd,
        QuickActionKind.inviteTeammate => context.l10n.teamInvite,
        QuickActionKind.analytics => context.l10n.navAnalytics,
        QuickActionKind.about => context.l10n.moreAbout,
      };
}

/// The words and the glyph for one Getting started step.
///
/// Same shape as [HomeShortcutDisplay] and [QuickActionLabel], for the same
/// reason: the enum stays `const` and the strings stay in ARB (hard rule 7).
final class GettingStartedStepLabel {
  static String title(BuildContext context, GettingStartedStep step) =>
      switch (step) {
        GettingStartedStep.addItem => context.l10n.homeStepAddItem,
        GettingStartedStep.listItem => context.l10n.homeStepListItem,
        GettingStartedStep.recordSale => context.l10n.homeStepRecordSale,
      };

  static String detail(BuildContext context, GettingStartedStep step) =>
      switch (step) {
        GettingStartedStep.addItem => context.l10n.homeStepAddItemDetail,
        GettingStartedStep.listItem => context.l10n.homeStepListItemDetail,
        GettingStartedStep.recordSale => context.l10n.homeStepRecordSaleDetail,
      };

  static IconData icon(GettingStartedStep step) => switch (step) {
    GettingStartedStep.addItem => AppIconConstant.bolt,
    GettingStartedStep.listItem => AppIconConstant.sell,
    GettingStartedStep.recordSale => AppIconConstant.payments,
  };

  /// Where the step is performed. Listing still points at Inventory because it
  /// starts on an item's Actions sheet; recording a sale has a screen of its
  /// own, so the checklist opens the action rather than the shelf it is on.
  static String route(GettingStartedStep step) => switch (step) {
    GettingStartedStep.addItem => AppRoutes.quickAdd,
    GettingStartedStep.listItem => AppRoutes.inventory,
    GettingStartedStep.recordSale => AppRoutes.recordSale,
  };

  /// Quick Add is pushed over Home; Inventory is a tab, and pushing a branch
  /// root leaves the seller on the wrong tab with a back button.
  static QuickActionOpen open(GettingStartedStep step) =>
      step == GettingStartedStep.addItem
      ? QuickActionOpen.push
      : QuickActionOpen.goTab;
}
