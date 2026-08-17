import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/router/app_routes.dart';

/// One row on the More screen.
///
/// **The label is not here.** A label is a user-facing string (hard rule 7),
/// so the row carries a [kind] and [MoreLabel] turns it into words — which is
/// also what keeps this list `const`.
class MoreDestination {
  const MoreDestination({
    required this.kind,
    required this.icon,
    required this.route,
    this.isBuilt = false,
  });

  final MoreDestinationKind kind;
  final IconData icon;
  final String route;

  /// False until the destination has a screen. Drives the disabled look and
  /// the "Soon" badge.
  final bool isBuilt;
}

/// What a More row points at.
enum MoreDestinationKind {
  sourcing,
  listings,
  expenses,
  reports,
  receipts,
  categories,
  locations,
  marketplaces,
  team,
  activity,
  tax,
  subscription,
  settings,
}

/// The words for a More row.
final class MoreLabel {
  static String of(BuildContext context, MoreDestinationKind kind) =>
      switch (kind) {
        MoreDestinationKind.sourcing => context.l10n.moreSourcing,
        MoreDestinationKind.listings => context.l10n.moreListings,
        MoreDestinationKind.expenses => context.l10n.moreExpenses,
        MoreDestinationKind.reports => context.l10n.moreReports,
        MoreDestinationKind.receipts => context.l10n.moreReceipts,
        MoreDestinationKind.categories => context.l10n.moreCategories,
        MoreDestinationKind.locations => context.l10n.moreLocations,
        MoreDestinationKind.marketplaces => context.l10n.moreMarketplaces,
        MoreDestinationKind.team => context.l10n.moreTeam,
        MoreDestinationKind.activity => context.l10n.moreActivity,
        MoreDestinationKind.tax => context.l10n.moreTax,
        MoreDestinationKind.subscription => context.l10n.moreSubscription,
        MoreDestinationKind.settings => context.l10n.moreSettings,
      };
}

/// What the More screen lists, kept off the widget that renders it.
///
/// **This list growing is fine. The bottom bar growing is not** — five tabs is
/// a product decision (hard rule 13), and this list is where the pressure to
/// add a sixth goes instead.
///
/// Destinations with no screen yet stay in the list and render disabled rather
/// than being hidden. Hiding them would make the app look finished; showing
/// them greyed says what is coming and stops a tap leading nowhere.
final class MoreConstant {
  static const List<MoreDestination> destinations = <MoreDestination>[
    MoreDestination(
      kind: MoreDestinationKind.sourcing,
      icon: Symbols.storefront_rounded,
      route: AppRoutes.sourcing,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.listings,
      icon: Symbols.sell_rounded,
      route: AppRoutes.listings,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.expenses,
      icon: Symbols.receipt_rounded,
      route: AppRoutes.expenses,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.reports,
      icon: Symbols.summarize_rounded,
      route: AppRoutes.reports,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.receipts,
      icon: Symbols.description_rounded,
      route: AppRoutes.receipts,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.categories,
      icon: Symbols.category_rounded,
      route: AppRoutes.categories,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.locations,
      icon: Symbols.shelves,
      route: AppRoutes.locations,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.marketplaces,
      icon: Symbols.hub_rounded,
      route: AppRoutes.marketplaces,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.team,
      icon: Symbols.group_rounded,
      route: AppRoutes.team,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.activity,
      icon: Symbols.history_rounded,
      route: AppRoutes.activity,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.tax,
      icon: Symbols.account_balance_rounded,
      route: AppRoutes.tax,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.subscription,
      icon: Symbols.workspace_premium_rounded,
      route: AppRoutes.subscription,
      isBuilt: true,
    ),
    MoreDestination(
      kind: MoreDestinationKind.settings,
      icon: Symbols.settings_rounded,
      route: AppRoutes.settings,
      isBuilt: true,
    ),
  ];
}
