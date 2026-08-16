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
/// **No route on it, unlike [QuickAccessAction].** Only two of the three are
/// a navigation at all — the first scrolls this screen — so the card asks
/// [HomeShortcutKind] what to do rather than pushing a path it was handed.
class HomeShortcut {
  const HomeShortcut({required this.kind, required this.icon});

  final HomeShortcutKind kind;
  final IconData icon;
}

/// The three ways out of Home.
enum HomeShortcutKind { quickAccess, search, analytics }

/// **The three cards that open Home** — owner's rule.
///
/// Home's own content answers "what needs attention today", and everything
/// that answers it is *inside* this screen. These three are the ways out: down
/// to Quick Access, sideways into global search, across to Analytics. They sit
/// first because a seller who opened the app to *go somewhere* should not have
/// to read a dashboard on the way.
///
/// **Three, and the list is closed.** A fourth would make this a launcher,
/// which is exactly what keeping Quick Access at the bottom exists to avoid —
/// the row works because it is short enough to take in without reading.
final class HomeShortcutConstant {
  static const List<HomeShortcut> shortcuts = <HomeShortcut>[
    HomeShortcut(
      kind: HomeShortcutKind.quickAccess,
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
        HomeShortcutKind.quickAccess => context.l10n.homeQuickAccess,
        HomeShortcutKind.search => context.l10n.homeShortcutSearch,
        HomeShortcutKind.analytics => context.l10n.navAnalytics,
      };
}

/// One create action, as Quick Access offers it.
///
/// **The label is not here.** A label is a user-facing string (hard rule 7),
/// so the tile carries a [kind] and `QuickAccessLabel` turns it into words —
/// which is also what keeps the list below `const`. The same shape
/// `MoreDestination` has, for the same reason.
class QuickAccessAction {
  const QuickAccessAction({
    required this.kind,
    required this.icon,
    required this.route,
  });

  final QuickAccessKind kind;
  final IconData icon;
  final String route;
}

/// Every create action in the app.
enum QuickAccessKind {
  quickAddItem,
  addItem,
  scan,
  recordPurchase,
  addExpense,
  addSource,
  addCategory,
  addLocation,
  about,
}

/// **Everything this app can create, plus the page explaining how it fits
/// together.**
///
/// Quick Access exists because the create actions are scattered by design —
/// each lives on the screen that owns the records it makes, behind that
/// screen's own `SdFabV3` (owner's rule). That is right for a seller already
/// on the screen and wrong for one who opened the app to add something: it is
/// three taps to record an expense from Home.
///
/// **About rides along at the end** — owner's call. It is not a create
/// action, and it is the one row here that is not: it sits two levels deep
/// under Settings, and the seller most likely to want "how does this work"
/// is the one still learning where everything is. Last in the list, so the
/// eight actions above it keep the section's shape.
///
/// **Adding a create action anywhere means adding it here.**
/// `test/features/home/quick_access_test.dart` fails when a screen grows an
/// `AppAddFabScaffold` this list does not know about, so the two cannot
/// drift.
final class QuickAccessConstant {
  static const List<QuickAccessAction> actions = <QuickAccessAction>[
    // Ordered by how often a reseller reaches for it, not alphabetically.
    // Quick Add is first because hard rule 2 says the product's speed rests
    // on it.
    QuickAccessAction(
      kind: QuickAccessKind.quickAddItem,
      icon: Symbols.bolt_rounded,
      route: AppRoutes.quickAdd,
    ),
    QuickAccessAction(
      kind: QuickAccessKind.scan,
      icon: Symbols.barcode_scanner_rounded,
      route: AppRoutes.scanner,
    ),
    QuickAccessAction(
      kind: QuickAccessKind.addItem,
      icon: Symbols.add_box_rounded,
      route: AppRoutes.addItem,
    ),
    QuickAccessAction(
      kind: QuickAccessKind.recordPurchase,
      icon: Symbols.shopping_bag_rounded,
      route: AppRoutes.addPurchase,
    ),
    QuickAccessAction(
      kind: QuickAccessKind.addExpense,
      icon: Symbols.receipt_rounded,
      route: AppRoutes.expenses,
    ),
    QuickAccessAction(
      kind: QuickAccessKind.addSource,
      icon: Symbols.storefront_rounded,
      route: AppRoutes.sources,
    ),
    QuickAccessAction(
      kind: QuickAccessKind.addCategory,
      icon: Symbols.category_rounded,
      route: AppRoutes.categories,
    ),
    QuickAccessAction(
      kind: QuickAccessKind.addLocation,
      icon: Symbols.shelves,
      route: AppRoutes.locations,
    ),
    QuickAccessAction(
      kind: QuickAccessKind.about,
      icon: Symbols.info_rounded,
      route: AppRoutes.about,
    ),
  ];
}

/// The words for a Quick Access tile.
final class QuickAccessLabel {
  static String of(BuildContext context, QuickAccessKind kind) => switch (kind) {
    QuickAccessKind.quickAddItem => context.l10n.quickAddTitle,
    QuickAccessKind.addItem => context.l10n.inventoryAddItem,
    QuickAccessKind.scan => context.l10n.inventoryScan,
    QuickAccessKind.recordPurchase => context.l10n.homeQuickRecordPurchase,
    QuickAccessKind.addExpense => context.l10n.homeQuickAddExpense,
    QuickAccessKind.addSource => context.l10n.homeQuickAddSource,
    QuickAccessKind.addCategory => context.l10n.categoryAdd,
    QuickAccessKind.addLocation => context.l10n.locationAdd,
    QuickAccessKind.about => context.l10n.moreAbout,
  };
}
