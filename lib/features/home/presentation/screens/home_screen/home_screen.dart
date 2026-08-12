import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../analytics/domain/entities/analytics_summary.dart';
import '../../../../analytics/providers.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../../orders/domain/entities/order.dart';
import '../../../../orders/providers.dart';
import '../../../../workspace/domain/entities/workspace.dart';
import '../../../../workspace/providers.dart';
import '../../../home_constant.dart';

part 'home_screen_activity_row.dart';
part 'home_screen_all_clear.dart';
part 'home_screen_attention_row.dart';
part 'home_screen_needs_attention.dart';
part 'home_screen_performance_block.dart';
part 'home_screen_recent_activity.dart';

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
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Workspace? workspace = ref.watch(currentWorkspaceProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: workspace?.name ?? context.l10n.appTitle,
        // No subtitle. "Your business today" was decoration, and it cost a
        // second row of chrome on the one screen whose content — what needs
        // attention — is the reason the app was opened.
        actions: <Widget>[
          IconButton(
            // Global search is reached from Home because Home is where a
            // seller starts (plan §5's global entry points). It sits outside
            // the shell so it can send them into any tab.
            onPressed: () => context.push(AppRoutes.search),
            icon: const Icon(Symbols.search_rounded),
            tooltip: 'Search',
          ),
          SizedBox(width: SdSpacingConstant.w8),
        ],
      ),
      body: ListView(
        padding: SdContentPaddingV3.fullBleed(context, floatingNav: true),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          const SdSectionHeaderV3(title: 'Needs Attention', first: true),
          const _NeedsAttention(),
          const SdSectionHeaderV3(title: 'Performance'),
          const _PerformanceBlock(),
          const SdSectionHeaderV3(title: 'Recent Activity'),
          const _RecentActivity(),
        ],
      ),
    );
  }
}
