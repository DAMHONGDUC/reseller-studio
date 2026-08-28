import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/router/app_routes.dart';

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
enum HomeShortcutKind { quickAction, search, analytics }

/// **The three cards that open Home** — owner's rule.
///
/// Home's own content answers "what needs attention today", and everything
/// that answers it is *inside* this screen. These three are the ways out: down
/// to Quick Action, sideways into global search, across to Analytics. They sit
/// first because a seller who opened the app to *go somewhere* should not have
/// to read a dashboard on the way.
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
      kind: HomeShortcutKind.analytics,
      icon: Symbols.bar_chart_rounded,
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
        HomeShortcutKind.analytics => context.l10n.navAnalytics,
      };
}

/// One create action, as Quick Action offers it.
///
/// **The label is not here.** A label is a user-facing string (hard rule 7),
/// so the row carries a [kind] and `QuickActionLabel` turns it into words —
/// which is also what keeps the list below `const`. The same shape
/// `MoreDestination` has, for the same reason.
class QuickAction {
  const QuickAction({required this.kind, required this.icon, this.route});

  final QuickActionKind kind;
  final IconData icon;

  /// **Null means the row is not a push.** Only Flow overview is: it opens a
  /// sheet, because the question it answers is asked while standing somewhere
  /// else in the app and a route would cost the seller their place.
  final String? route;
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
  flowOverview,
  about,
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
/// rule: About last, Flow overview just above it. About lives two levels deep
/// under Settings, so this is what keeps it findable; putting both at the end
/// is what stops a seller scanning for "add" from stepping over them. Nothing
/// else non-create joins them without the same decision.
///
/// **Adding a create action anywhere means adding it here.**
/// `test/features/home/quick_access_test.dart` fails when a screen grows an
/// `AppAddFabScaffold` this list does not know about, so the two cannot
/// drift.
final class QuickActionConstant {
  static const List<QuickAction> actions = <QuickAction>[
    // Ordered by how often a reseller reaches for it, not alphabetically.
    // Quick Add is first because hard rule 2 says the product's speed rests
    // on it.
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
    // Last of the create actions, before About: a seller invites a teammate
    // once, and everything above it is something they do every week.
    QuickAction(
      kind: QuickActionKind.inviteTeammate,
      icon: Symbols.group_add_rounded,
      route: AppRoutes.team,
    ),
    // The two that explain rather than create. Flow overview answers "how do
    // I run my week with this", which is the question that comes before any
    // of the rows above it — and it is the only row here that opens a sheet.
    QuickAction(
      kind: QuickActionKind.flowOverview,
      icon: Symbols.account_tree_rounded,
    ),
    QuickAction(
      kind: QuickActionKind.about,
      icon: Symbols.info_rounded,
      route: AppRoutes.about,
    ),
  ];
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
        QuickActionKind.flowOverview => context.l10n.homeFlowOverview,
        QuickActionKind.about => context.l10n.moreAbout,
      };
}
