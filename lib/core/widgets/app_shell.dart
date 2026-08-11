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
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => SdScaffoldV3(
    body: shell,
    bottomNavigationBar: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.sdTheme3.border)),
      ),
      child: NavigationBar(
        selectedIndex: shell.currentIndex,
        backgroundColor: context.sdTheme3.background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: context.colorScheme3.secondaryContainer,
        // Labels always shown: five icons with no words is a memory test, and
        // "Analytics" and "More" have no glyph a seller reads unambiguously.
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (int index) => shell.goBranch(
          index,
          // Re-tapping the active tab pops that branch to its root.
          initialLocation: index == shell.currentIndex,
        ),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Symbols.home_rounded),
            selectedIcon: const Icon(Symbols.home_rounded, fill: 1),
            label: context.l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.inventory_2_rounded),
            selectedIcon: const Icon(Symbols.inventory_2_rounded, fill: 1),
            label: context.l10n.navInventory,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.receipt_long_rounded),
            selectedIcon: const Icon(Symbols.receipt_long_rounded, fill: 1),
            label: context.l10n.navOrders,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.bar_chart_rounded),
            selectedIcon: const Icon(Symbols.bar_chart_rounded, fill: 1),
            label: context.l10n.navAnalytics,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.menu_rounded),
            selectedIcon: const Icon(Symbols.menu_rounded, fill: 1),
            label: context.l10n.navMore,
          ),
        ],
      ),
    ),
  );
}
