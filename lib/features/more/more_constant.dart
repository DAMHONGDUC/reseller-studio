import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/router/app_routes.dart';

/// One row on the More screen.
///
/// Public because [MoreConstant] exposes the list, and a constants class that
/// hands back a private type is a class nobody outside the file can read.
class MoreDestination {
  const MoreDestination({
    required this.label,
    required this.icon,
    required this.route,
    this.isBuilt = false,
  });

  final String label;
  final IconData icon;
  final String route;

  /// False until the destination has a screen. Drives the disabled look and
  /// the "Soon" badge.
  final bool isBuilt;
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
      label: 'Sourcing',
      icon: Symbols.storefront_rounded,
      route: AppRoutes.sourcing,
      isBuilt: true,
    ),
    MoreDestination(
      label: 'Listings',
      icon: Symbols.sell_rounded,
      route: AppRoutes.listings,
      isBuilt: true,
    ),
    MoreDestination(
      label: 'Expenses',
      icon: Symbols.receipt_rounded,
      route: AppRoutes.expenses,
      isBuilt: true,
    ),
    MoreDestination(
      label: 'Reports',
      icon: Symbols.summarize_rounded,
      route: AppRoutes.reports,
      isBuilt: true,
    ),
    MoreDestination(
      label: 'Receipts',
      icon: Symbols.description_rounded,
      route: AppRoutes.receipts,
      isBuilt: true,
    ),
    MoreDestination(
      label: 'Categories',
      icon: Symbols.category_rounded,
      route: AppRoutes.categories,
      isBuilt: true,
    ),
    MoreDestination(
      label: 'Locations',
      icon: Symbols.shelves,
      route: AppRoutes.locations,
      isBuilt: true,
    ),
    MoreDestination(
      label: 'Marketplaces',
      icon: Symbols.hub_rounded,
      route: AppRoutes.marketplaces,
      isBuilt: true,
    ),
    MoreDestination(
      label: 'Team',
      icon: Symbols.group_rounded,
      route: AppRoutes.team,
      isBuilt: true,
    ),
    MoreDestination(
      label: 'Settings',
      icon: Symbols.settings_rounded,
      route: AppRoutes.settings,
      isBuilt: true,
    ),
  ];
}
