import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../extensions/context_extensions.dart';

/// The five-tab frame every signed-in screen lives in.
///
/// The tabs are fixed by the master plan (§5) and the list below is the whole
/// of it: **Home, Inventory, Orders, Analytics, More**. Sourcing, Listings,
/// Finance, Shipping and Offers are deliberately *not* tabs — they live under
/// More, because a bottom bar answers "what am I doing right now" and only
/// five things qualify.
///
/// `StatefulShellRoute.indexedStack` gives each tab its own [Navigator], so a
/// seller three screens deep in Inventory can check an order and come back to
/// exactly where they were. That is why tapping the current tab pops it to
/// its root rather than doing nothing.
///
/// **The bar floats and the body runs underneath it** — `extendBody`, plus
/// every tab screen padding by `SdContentPaddingV3.floatingBarInset`. Without
/// both, the glass has nothing moving behind it to refract and the last row
/// of every list hides under the bar.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    extendBody: true,
    body: shell,
    bottomNavigationBar: SdGlassNavBarV3(
      selectedIndex: shell.currentIndex,
      onSelected: (int index) => shell.goBranch(
        index,
        // Re-tapping the active tab pops that branch to its root.
        initialLocation: index == shell.currentIndex,
      ),
      destinations: <SdNavDestinationV3>[
        SdNavDestinationV3(
          icon: Symbols.home_rounded,
          selectedIcon: Symbols.home_rounded,
          label: context.l10n.navHome,
        ),
        SdNavDestinationV3(
          icon: Symbols.inventory_2_rounded,
          selectedIcon: Symbols.inventory_2_rounded,
          label: context.l10n.navInventory,
        ),
        SdNavDestinationV3(
          icon: Symbols.receipt_long_rounded,
          selectedIcon: Symbols.receipt_long_rounded,
          label: context.l10n.navOrders,
        ),
        SdNavDestinationV3(
          icon: Symbols.bar_chart_rounded,
          selectedIcon: Symbols.bar_chart_rounded,
          label: context.l10n.navAnalytics,
        ),
        SdNavDestinationV3(
          icon: Symbols.menu_rounded,
          selectedIcon: Symbols.menu_rounded,
          label: context.l10n.navMore,
        ),
      ],
    ),
  );
}
