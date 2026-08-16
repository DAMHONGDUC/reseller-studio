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

  /// How many Quick Access tiles fit across the row.
  static const int quickAccessColumns = 4;

  /// Width over height of one tile. Taller than square because the label
  /// under the glyph runs to two lines — "Record a purchase" does not fit on
  /// one at this width, and a tile that clips its own label is worse than a
  /// slightly tall grid.
  static const double quickAccessTileRatio = 0.78;
}

/// One create action, as Quick Access offers it.
///
/// **The label is not here.** A label is a user-facing string (hard rule 7),
/// so the tile carries a [kind] and `QuickAddLabel` turns it into words —
/// which is also what keeps the list below `const`. The same shape
/// `MoreDestination` has, for the same reason.
class QuickAddAction {
  const QuickAddAction({
    required this.kind,
    required this.icon,
    required this.route,
  });

  final QuickAddKind kind;
  final IconData icon;
  final String route;
}

/// Every create action in the app.
enum QuickAddKind {
  quickAddItem,
  addItem,
  scan,
  recordPurchase,
  addExpense,
  addSource,
  addCategory,
  addLocation,
}

/// **The one list of everything this app can create.**
///
/// Quick Access exists because the create actions are scattered by design —
/// each lives on the screen that owns the records it makes, behind that
/// screen's own `SdFabV3` (owner's rule). That is right for a seller already
/// on the screen and wrong for one who opened the app to add something: it is
/// three taps to record an expense from Home.
///
/// **Adding a create action anywhere means adding it here.**
/// `test/features/home/quick_access_test.dart` fails when a screen grows an
/// `AppAddFabScaffold` this list does not know about, so the two cannot drift.
final class QuickAddConstant {
  static const List<QuickAddAction> actions = <QuickAddAction>[
    // Ordered by how often a reseller reaches for it, not alphabetically.
    // Quick Add is first because hard rule 2 says the product's speed rests
    // on it.
    QuickAddAction(
      kind: QuickAddKind.quickAddItem,
      icon: Symbols.bolt_rounded,
      route: AppRoutes.quickAdd,
    ),
    QuickAddAction(
      kind: QuickAddKind.scan,
      icon: Symbols.barcode_scanner_rounded,
      route: AppRoutes.scanner,
    ),
    QuickAddAction(
      kind: QuickAddKind.addItem,
      icon: Symbols.add_box_rounded,
      route: AppRoutes.addItem,
    ),
    QuickAddAction(
      kind: QuickAddKind.recordPurchase,
      icon: Symbols.shopping_bag_rounded,
      route: AppRoutes.addPurchase,
    ),
    QuickAddAction(
      kind: QuickAddKind.addExpense,
      icon: Symbols.receipt_rounded,
      route: AppRoutes.expenses,
    ),
    QuickAddAction(
      kind: QuickAddKind.addSource,
      icon: Symbols.storefront_rounded,
      route: AppRoutes.sources,
    ),
    QuickAddAction(
      kind: QuickAddKind.addCategory,
      icon: Symbols.category_rounded,
      route: AppRoutes.categories,
    ),
    QuickAddAction(
      kind: QuickAddKind.addLocation,
      icon: Symbols.shelves,
      route: AppRoutes.locations,
    ),
  ];
}

/// The words for a Quick Access tile.
final class QuickAddLabel {
  static String of(BuildContext context, QuickAddKind kind) => switch (kind) {
    QuickAddKind.quickAddItem => context.l10n.quickAddTitle,
    QuickAddKind.addItem => context.l10n.inventoryAddItem,
    QuickAddKind.scan => context.l10n.inventoryScan,
    QuickAddKind.recordPurchase => context.l10n.homeQuickRecordPurchase,
    QuickAddKind.addExpense => context.l10n.homeQuickAddExpense,
    QuickAddKind.addSource => context.l10n.homeQuickAddSource,
    QuickAddKind.addCategory => context.l10n.categoryAdd,
    QuickAddKind.addLocation => context.l10n.locationAdd,
  };
}
