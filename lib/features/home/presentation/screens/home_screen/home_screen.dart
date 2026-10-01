import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/account/account_kind.dart';
import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/local/local_providers.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_marketplace_tag.dart';
import '../../../../../core/widgets/app_profit_hero.dart';
import '../../../../../core/widgets/app_row_chevron.dart';
import '../../../../../core/widgets/app_section.dart';
import '../../../../../core/widgets/app_status_card.dart';
import '../../../../../core/widgets/notification_bell.dart';
import '../../../../../core/widgets/workspace_switcher_sheet.dart';
import '../../../../analytics/domain/entities/analytics_summary.dart';
import '../../../../analytics/providers.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../../offers/domain/entities/offer.dart';
import '../../../../offers/providers.dart';
import '../../../../orders/domain/entities/order.dart';
import '../../../../orders/domain/services/payout_reconciliation.dart';
import '../../../../orders/providers.dart';
import '../../../../subscription/domain/enums/seller_plan.dart';
import '../../../../subscription/providers.dart';
import '../../../../workspace/domain/entities/workspace.dart';
import '../../../../workspace/providers.dart';
import '../../../domain/enums/getting_started_step.dart';
import '../../../domain/enums/workspace_activity.dart';
import '../../../home_constant.dart';
import '../../../providers.dart';
import '../../widgets/flow_overview_sheet.dart';

part 'home_screen_activity_row.dart';
part 'home_screen_all_clear.dart';
part 'home_screen_attention_tile.dart';
part 'home_screen_flow_overview.dart';
part 'home_screen_getting_started.dart';
part 'home_screen_guest_banner.dart';
part 'home_screen_needs_attention.dart';
part 'home_screen_performance_block.dart';
part 'home_screen_premium_banner.dart';
part 'home_screen_quick_action.dart';
part 'home_screen_recent_activity.dart';
part 'home_screen_shortcuts.dart';
part 'home_screen_start_here.dart';

/// Home — "what do I need to do today?".
///
/// **Needs Attention opens the screen** — owner's rule, and the plan's own
/// core principle: *tell the seller what needs attention today, then make the
/// action fast*. It is a grid of tiles with the count set large, so the
/// number is the first thing read rather than the last.
///
/// **The three create actions sit directly under it**, as one filled button
/// and two outlined ones — the fast half of the same principle. See
/// `HomeShortcutConstant`.
///
/// Below that the hierarchy is deliberate and has exactly one loud element:
/// profit as a filled hero, then three quiet tiles. The whole order is in
/// `lib/features/home/CLAUDE.md`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          SdAppBarActionButtonV3(
            icon: AppIconConstant.search,
            tooltip: context.l10n.homeShortcutSearch,
            // Global search is reached from Home because Home is where a
            // seller starts (plan §5's global entry points). It sits outside
            // the shell so it can send them into any tab.
            // No account needed: search reads the store this seller already
            // has, whichever one that is.
            onPressed: () => context.push(AppRoutes.search),
          ),
          SizedBox(width: SdSpacingConstant.w8),
        ],
      ),
      body: ListView(
        padding: SdContentPaddingV3.fullBleed(context, floatingNav: true),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          // Above the upsell on purpose: one offers more, the other says what
          // is about to be lost.
          const _HomeGuestBanner(),
          if (_HomeGuestBanner.shows(ref))
            SizedBox(height: SdContentPaddingV3.listItemGap),
          const _HomePremiumBanner(),
          if (_HomePremiumBanner.shows(ref))
            SizedBox(height: SdContentPaddingV3.listItemGap),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: SdSectionHeaderV3(
              title: context.l10n.homeNeedsAttention,
              first: true,
            ),
          ),
          const _NeedsAttention(),
          SizedBox(height: SdContentPaddingV3.listItemGap),
          const _HomeShortcuts(),
          const _GettingStarted(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: SdSectionHeaderV3(title: context.l10n.homePerformance),
          ),
          const _PerformanceBlock(),
          const _HomeFlowOverview(),
          const _RecentActivity(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: SdSectionHeaderV3(
              title: context.l10n.homeQuickAction,
              subtitle: context.l10n.homeQuickActionSubtitle,
            ),
          ),
          const _QuickAction(),
        ],
      ),
    );
  }
}
