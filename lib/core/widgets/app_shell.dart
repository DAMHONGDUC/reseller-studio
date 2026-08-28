import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../analytics/app_analytics.dart';
import '../constants/log_tag_constant.dart';
import '../constants/nav_tab_constant.dart';
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
/// of every list hides under the bar. The body is wrapped in
/// `SdFloatingBarScopeV3` for the one thing that cannot pad itself: a
/// snackbar, which renders into the root overlay above the whole app.
///
/// **Screen views for the five tabs are logged here and nowhere else.**
/// Switching a branch pushes no route, so a navigator observer sees nothing
/// and the router cannot report it. This is a widget lifecycle rather than a
/// controller only because there is no controller between a tab tap and the
/// shell — the event still goes through [AppAnalytics] and sits next to its
/// [SdLogger.action], and it is never raised from `build`.
class AppShell extends StatefulWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();

    // The tab the app opens on is a screen view like any other; without this
    // the first one of every session is missing.
    _logTab(widget.shell.currentIndex);
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    final int index = widget.shell.currentIndex;

    // Re-tapping the active tab pops it to root and leaves the index alone —
    // that is not a new screen view.
    if (index != oldWidget.shell.currentIndex) _logTab(index);
  }

  void _logTab(int index) {
    final String? tab = NavTabConstant.nameAt(index);

    if (tab == null) {
      SdLogger.warning(
        LogTagConstant.navigation,
        'Tab index outside NavTabConstant',
        <String, Object>{'index': index},
      );

      return;
    }

    SdLogger.action(LogTagConstant.navigation, 'Tab viewed', <String, Object>{
      'tab': tab,
    });
    AppAnalytics.instance.tabViewed(tab: tab);
  }

  @override
  Widget build(BuildContext context) => SdBottomNavigationV3(
    body: widget.shell,
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
    selectedIndex: widget.shell.currentIndex,
    onSelected: (int index) => widget.shell.goBranch(
      index,
      // Re-tapping the active tab pops that branch to its root.
      initialLocation: index == widget.shell.currentIndex,
    ),
  );
}
