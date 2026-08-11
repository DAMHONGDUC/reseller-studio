import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../analytics/domain/entities/analytics_summary.dart';
import '../../../../analytics/providers.dart';
import '../../../../inventory/domain/entities/item.dart';
import '../../../../orders/domain/entities/order.dart';
import '../../../../orders/providers.dart';
import '../../../../workspace/domain/entities/workspace.dart';
import '../../../../workspace/providers.dart';

/// Home — "what do I need to do today?".
///
/// **Needs Attention sits above Today's Overview**, inverting the order the
/// plan lists them in (§6). A seller opening the app at 8am needs the orders
/// waiting to ship, not last night's revenue; the numbers are what they check
/// second. The plan's own core principle — *tell the seller what needs
/// attention today, then make the action fast* — is the tiebreaker.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Workspace? workspace = ref.watch(currentWorkspaceProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: workspace?.name ?? context.l10n.appTitle,
        subtitle: workspace == null ? null : 'Today',
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Symbols.notifications_rounded),
            tooltip: 'Notifications',
          ),
          SizedBox(width: SdSpacingConstant.w8),
        ],
      ),
      body: ListView(
        padding: SdContentPaddingV3.fullBleed(context),
        children: const <Widget>[
          SdSectionHeaderV3(title: 'Needs Attention', first: true),
          _NeedsAttention(),
          SdSectionHeaderV3(title: "Today's Overview"),
          _OverviewGrid(),
        ],
      ),
    );
  }
}

/// The four things that can be waiting on a seller, each with its count.
///
/// A block renders **only when it has something in it**. A permanent list of
/// zeroes trains the eye to skip the whole section, which defeats the one
/// thing this screen exists to do.
class _NeedsAttention extends ConsumerWidget {
  const _NeedsAttention();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> pending = ref.watch(ordersNeedingActionProvider);
    final List<Item> stale = ref.watch(staleItemsProvider);
    final List<Item> unlisted = ref.watch(unlistedItemsProvider);
    final DateTime now = DateTime.now();

    final int overdue = pending
        .where((Order order) => order.isOverdue(now) ?? false)
        .length;

    final List<Widget> rows = <Widget>[
      if (pending.isNotEmpty)
        _AttentionRow(
          icon: Symbols.local_shipping_rounded,
          label: 'Orders to ship',
          count: pending.length,
          // An overdue order is a different problem from a pending one: the
          // penalty has already started. Saying so on the row is the whole
          // value of the block.
          detail: overdue > 0 ? '$overdue overdue' : null,
          tone: overdue > 0 ? SdBadgeToneV3.danger : SdBadgeToneV3.warning,
          onTap: () => context.go(AppRoutes.orders),
        ),
      if (unlisted.isNotEmpty)
        _AttentionRow(
          icon: Symbols.sell_rounded,
          label: 'Items to list',
          count: unlisted.length,
          tone: SdBadgeToneV3.info,
          onTap: () => context.go(AppRoutes.inventory),
        ),
      if (stale.isNotEmpty)
        _AttentionRow(
          icon: Symbols.hourglass_bottom_rounded,
          label: 'Stale inventory',
          count: stale.length,
          detail: 'listed over 60 days',
          tone: SdBadgeToneV3.warning,
          onTap: () => context.go(AppRoutes.inventory),
        ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SdContentPaddingV3.horizontal,
      ),
      child: rows.isEmpty
          ? SdCardV3(
              child: Row(
                children: <Widget>[
                  SdIconV3(
                    Symbols.check_circle_rounded,
                    color: context.sdTheme3.success,
                  ),
                  SizedBox(width: SdSpacingConstant.w12),
                  Expanded(
                    child: Text(
                      'Nothing needs your attention right now.',
                      style: context.textTheme3.bodyMedium!.muted3(context),
                    ),
                  ),
                ],
              ),
            )
          : SdCardV3(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < rows.length; i++) ...<Widget>[
                    rows[i],
                    if (i != rows.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: context.sdTheme3.divider,
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.tone,
    this.detail,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final SdBadgeToneV3 tone;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: SdContentPaddingV3.row,
      child: Row(
        children: <Widget>[
          SdIconV3(icon, color: context.sdTheme3.textSecondary),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: context.textTheme3.bodyLarge!.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: context.textTheme3.bodySmall!.muted3(context),
                  ),
              ],
            ),
          ),
          SdBadgeV3(label: '$count', tone: tone),
          SizedBox(width: SdSpacingConstant.w8),
          SdIconV3(
            Symbols.chevron_right_rounded,
            size: SdIconV3.smallSize,
            color: context.sdTheme3.textTertiary,
          ),
        ],
      ),
    ),
  );
}

class _OverviewGrid extends ConsumerWidget {
  const _OverviewGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsSummary summary = ref.watch(analyticsSummaryProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SdContentPaddingV3.horizontal,
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // 1.35, not 1.6: a tile is label + figure + caption, and at 1.6 the
        // caption row overflowed the fixed cell height by 4px. `GridView`
        // gives every cell the same height, so the tallest possible content —
        // a tile *with* a caption — is what sets this.
        childAspectRatio: 1.35,
        mainAxisSpacing: SdContentPaddingV3.listItemGap,
        crossAxisSpacing: SdContentPaddingV3.listItemGap,
        children: <Widget>[
          SdStatTileV3(
            label: 'Revenue',
            value: summary.revenue == null
                ? null
                : context.money(summary.revenue, compact: true),
            icon: Symbols.payments_rounded,
            caption: '${summary.orderCount} orders',
          ),
          SdStatTileV3(
            label: 'Profit',
            value: summary.netProfit == null
                ? null
                : context.money(summary.netProfit, compact: true),
            // Loss is a real outcome and must not read as good news.
            tone: (summary.netProfit?.isNegative ?? false)
                ? SdStatToneV3.loss
                : SdStatToneV3.profit,
            icon: Symbols.trending_up_rounded,
            caption: summary.isProfitComplete
                ? context.percent(summary.margin)
                : 'partial — some costs missing',
          ),
          SdStatTileV3(
            label: 'Units sold',
            value: '${summary.unitsSold}',
            icon: Symbols.receipt_long_rounded,
          ),
          SdStatTileV3(
            label: 'Inventory',
            value: summary.inventoryValue == null
                ? null
                : context.money(summary.inventoryValue, compact: true),
            icon: Symbols.inventory_2_rounded,
            caption: '${summary.itemsOnHand} on hand',
          ),
        ],
      ),
    );
  }
}
