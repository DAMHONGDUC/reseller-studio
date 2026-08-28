import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

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

/// One of the three cards at the top of Home.
///
/// **No route on it, unlike [QuickAction].** Only two of the three are
/// a navigation at all — the first scrolls this screen — so the card asks
/// [HomeShortcutKind] what to do rather than pushing a path it was handed.
class HomeShortcut {
  const HomeShortcut({required this.kind, required this.icon});

  final HomeShortcutKind kind;
  final IconData icon;
}

/// The three ways out of Home.
enum HomeShortcutKind { quickAction, search, scan }

/// **The three cards that open Home** — owner's rule.
///
/// Home's own content answers "what needs attention today", and everything
/// that answers it is *inside* this screen. These three are the ways out: down
/// to Quick Action, sideways into global search, and into the scanner.
/// They sit first because a seller who opened the app to *go somewhere* should
/// not have to read a dashboard on the way.
///
/// Flow overview now gets a full section immediately below this row. Scan
/// takes its card because it is a frequent action a seller starts while
/// holding an item, and the shortcut row is the fastest way into it.
///
/// **Three, and the list is closed.** A fourth would make this a launcher,
/// which is exactly what keeping the create actions at the bottom exists to
/// avoid —
/// the row works because it is short enough to take in without reading.
final class HomeShortcutConstant {
  static const List<HomeShortcut> shortcuts = <HomeShortcut>[
    HomeShortcut(
      kind: HomeShortcutKind.quickAction,
      icon: Symbols.bolt_rounded,
    ),
    HomeShortcut(kind: HomeShortcutKind.search, icon: Symbols.search_rounded),
    HomeShortcut(
      kind: HomeShortcutKind.scan,
      icon: Symbols.barcode_scanner_rounded,
    ),
  ];
}

/// The words for a Home shortcut card.
///
/// Each reuses the key its destination already owns — a card that said
/// something other than the section it lands on is a card that lies.
final class HomeShortcutLabel {
  static String of(BuildContext context, HomeShortcutKind kind) =>
      switch (kind) {
        HomeShortcutKind.quickAction => context.l10n.homeQuickAction,
        HomeShortcutKind.search => context.l10n.homeShortcutSearch,
        HomeShortcutKind.scan => context.l10n.inventoryScan,
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
  addItem,
  scan,
  recordPurchase,
  addExpense,
  addSource,
  addCategory,
  addLocation,
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
          icon: Symbols.bolt_rounded,
          route: AppRoutes.quickAdd,
        ),
        QuickAction(
          kind: QuickActionKind.scan,
          icon: Symbols.barcode_scanner_rounded,
          route: AppRoutes.scanner,
        ),
        QuickAction(
          kind: QuickActionKind.addItem,
          icon: Symbols.add_box_rounded,
          route: AppRoutes.addItem,
        ),
        QuickAction(
          kind: QuickActionKind.addCategory,
          icon: Symbols.category_rounded,
          route: AppRoutes.categories,
        ),
        QuickAction(
          kind: QuickActionKind.addLocation,
          icon: Symbols.shelves,
          route: AppRoutes.locations,
        ),
      ],
    ),
    QuickActionSection(
      kind: QuickActionSectionKind.operations,
      actions: <QuickAction>[
        QuickAction(
          kind: QuickActionKind.recordPurchase,
          icon: Symbols.shopping_bag_rounded,
          route: AppRoutes.addPurchase,
        ),
        QuickAction(
          kind: QuickActionKind.addExpense,
          icon: Symbols.receipt_rounded,
          route: AppRoutes.expenses,
        ),
        QuickAction(
          kind: QuickActionKind.addSource,
          icon: Symbols.storefront_rounded,
          route: AppRoutes.sources,
        ),
      ],
    ),
    QuickActionSection(
      kind: QuickActionSectionKind.business,
      actions: <QuickAction>[
        QuickAction(
          kind: QuickActionKind.inviteTeammate,
          icon: Symbols.group_add_rounded,
          route: AppRoutes.team,
        ),
      ],
    ),
    QuickActionSection(
      kind: QuickActionSectionKind.app,
      actions: <QuickAction>[
        QuickAction(
          kind: QuickActionKind.analytics,
          icon: Symbols.bar_chart_rounded,
          route: AppRoutes.analytics,
          open: QuickActionOpen.goTab,
        ),
        QuickAction(
          kind: QuickActionKind.about,
          icon: Symbols.info_rounded,
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
        QuickActionKind.addItem => context.l10n.inventoryAddItem,
        QuickActionKind.scan => context.l10n.inventoryScan,
        QuickActionKind.recordPurchase => context.l10n.homeQuickRecordPurchase,
        QuickActionKind.addExpense => context.l10n.homeQuickAddExpense,
        QuickActionKind.addSource => context.l10n.homeQuickAddSource,
        QuickActionKind.addCategory => context.l10n.categoryAdd,
        QuickActionKind.addLocation => context.l10n.locationAdd,
        QuickActionKind.inviteTeammate => context.l10n.teamInvite,
        QuickActionKind.analytics => context.l10n.navAnalytics,
        QuickActionKind.about => context.l10n.moreAbout,
      };
}

/// The words and the glyph for one Getting started step.
///
/// Same shape as [HomeShortcutLabel] and [QuickActionLabel], for the same
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
    GettingStartedStep.addItem => Symbols.bolt_rounded,
    GettingStartedStep.listItem => Symbols.sell_rounded,
    GettingStartedStep.recordSale => Symbols.payments_rounded,
  };

  /// Where the step is performed. Steps two and three share Inventory because
  /// both start on an item's Actions sheet — the checklist points at the
  /// screen that owns the move, it does not learn how to make it.
  static String route(GettingStartedStep step) => switch (step) {
    GettingStartedStep.addItem => AppRoutes.quickAdd,
    GettingStartedStep.listItem => AppRoutes.inventory,
    GettingStartedStep.recordSale => AppRoutes.inventory,
  };

  /// Quick Add is pushed over Home; Inventory is a tab, and pushing a branch
  /// root leaves the seller on the wrong tab with a back button.
  static QuickActionOpen open(GettingStartedStep step) =>
      step == GettingStartedStep.addItem
      ? QuickActionOpen.push
      : QuickActionOpen.goTab;
}
