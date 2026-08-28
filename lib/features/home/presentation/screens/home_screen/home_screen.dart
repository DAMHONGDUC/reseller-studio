import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/utils/scroll_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/notification_bell.dart';
import '../../../../../core/widgets/workspace_switcher_sheet.dart';
import '../../../../analytics/domain/entities/analytics_summary.dart';
import '../../../../analytics/providers.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../../offers/domain/entities/offer.dart';
import '../../../../offers/providers.dart';
import '../../../../orders/domain/entities/order.dart';
import '../../../../orders/providers.dart';
import '../../../../workspace/domain/entities/workspace.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/enums/workspace_activity.dart';
import '../../../home_constant.dart';
import '../../../providers.dart';
import '../../widgets/flow_overview_sheet.dart';

part 'home_screen_activity_row.dart';
part 'home_screen_all_clear.dart';
part 'home_screen_attention_row.dart';
part 'home_screen_flow_overview.dart';
part 'home_screen_needs_attention.dart';
part 'home_screen_performance_block.dart';
part 'home_screen_quick_action.dart';
part 'home_screen_recent_activity.dart';
part 'home_screen_shortcuts.dart';
part 'home_screen_start_here.dart';

/// Home — "what do I need to do today?".
///
/// **Needs Attention sits above the numbers**, inverting the order the plan
/// lists them in (§6). A seller opening the app at 8am needs the orders
/// waiting to ship, not last night's revenue. The plan's own core principle —
/// *tell the seller what needs attention today, then make the action fast* —
/// is the tiebreaker, and it outranks the fact that a hero card at the very
/// top would look stronger.
///
/// Below that the hierarchy is deliberate and has exactly one loud element:
/// profit as a filled hero, then three quiet tiles. Four equal tiles said
/// four things mattered equally, which on a dashboard means none of them
/// does.
///
/// **Three shortcut cards sit above even Needs Attention** — owner's rule,
/// and the one thing on this screen that outranks it. They are ways *out* of
/// Home rather than content, so they are read in a glance and skipped by
/// anyone who came to read the dashboard. See `HomeShortcutConstant`.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Owned here because the Quick Access card scrolls this list, and a
  /// controller a child created is one the screen cannot drive.
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  /// Quick Action is the last section (owner's rule, held by
  /// `test/features/home/quick_action_test.dart`), so the end of the list is
  /// where it is — no key to keep in sync with a section that moved.
  void _toQuickAction() => ScrollUtils.toEnd(_controller);

  @override
  Widget build(BuildContext context) {
    final Workspace? workspace = ref.watch(currentWorkspaceProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: workspace?.name ?? context.l10n.appTitle,
        // Slack's move: the title names the business and is how you change
        // it. Only offered once there is one — a signed-out visitor has
        // nothing to switch between, and a chevron opening an empty sheet is
        // worse than no chevron.
        onTitleTap: workspace == null
            ? null
            : () => WorkspaceSwitcherSheet.show(context),
        // No subtitle. "Your business today" was decoration, and it cost a
        // second row of chrome on the one screen whose content — what needs
        // attention — is the reason the app was opened.
        actions: <Widget>[
          // The inbox first, then search: one says something happened, the
          // other is a place to go looking.
          const NotificationBell(),
          IconButton(
            // Global search is reached from Home because Home is where a
            // seller starts (plan §5's global entry points). It sits outside
            // the shell so it can send them into any tab.
            onPressed: () {
              if (!NavigationUtils.requireSignIn(context, ref)) return;

              context.push(AppRoutes.search);
            },
            icon: const Icon(Symbols.search_rounded),
            tooltip: context.l10n.homeShortcutSearch,
          ),
          SizedBox(width: SdSpacingConstant.w8),
        ],
      ),
      body: ListView(
        controller: _controller,
        padding: SdContentPaddingV3.fullBleed(context, floatingNav: true),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          _HomeShortcuts(onQuickAction: _toQuickAction),
          const _HomeFlowOverview(),
          SdSectionHeaderV3(title: context.l10n.homeNeedsAttention),
          const _NeedsAttention(),
          SdSectionHeaderV3(title: context.l10n.homePerformance),
          const _PerformanceBlock(),
          const _RecentActivity(),
          SdSectionHeaderV3(
            title: context.l10n.homeQuickAction,
            subtitle: context.l10n.homeQuickActionSubtitle,
          ),
          const _QuickAction(),
        ],
      ),
    );
  }
}
