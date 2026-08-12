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
        subtitle: workspace == null ? null : 'Your business today',
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
        padding: SdContentPaddingV3.fullBleed(context, floatingNav: true),
        children: const <Widget>[
          SdSectionHeaderV3(title: 'Needs Attention', first: true),
          _NeedsAttention(),
          SdSectionHeaderV3(title: 'Performance'),
          _PerformanceBlock(),
          SdSectionHeaderV3(title: 'Recent Activity'),
          _RecentActivity(),
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
          detail: overdue > 0 ? '$overdue overdue' : 'none overdue',
          tint: overdue > 0
              ? context.sdTheme3.danger
              : context.sdTheme3.warning,
          onTap: () => context.go(AppRoutes.orders),
        ),
      if (unlisted.isNotEmpty)
        _AttentionRow(
          icon: Symbols.sell_rounded,
          label: 'Items to list',
          count: unlisted.length,
          detail: 'in stock, not listed anywhere',
          tint: context.sdTheme3.info,
          onTap: () => context.go(AppRoutes.inventory),
        ),
      if (stale.isNotEmpty)
        _AttentionRow(
          icon: Symbols.hourglass_bottom_rounded,
          label: 'Stale inventory',
          count: stale.length,
          detail: 'listed over 60 days',
          tint: context.sdTheme3.warning,
          onTap: () => context.go(AppRoutes.inventory),
        ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: rows.isEmpty
          ? const _AllClear()
          : SdCardV3(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < rows.length; i++) ...<Widget>[
                    rows[i],
                    if (i != rows.length - 1)
                      Padding(
                        padding: EdgeInsets.only(
                          // Indented to clear the icon tile, so the rule
                          // separates the text column rather than cutting the
                          // whole card in half.
                          left:
                              SdSpacingConstant.w16 +
                              SdIconTileSizeV3.medium.box +
                              SdSpacingConstant.w12,
                        ),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: context.sdTheme3.divider,
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _AllClear extends StatelessWidget {
  const _AllClear();

  @override
  Widget build(BuildContext context) => SdCardV3(
    child: Row(
      children: <Widget>[
        SdIconTileV3(
          icon: Symbols.check_circle_rounded,
          tint: context.sdTheme3.success,
        ),
        SizedBox(width: SdSpacingConstant.w12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'All clear',
                style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
              Text(
                'Nothing needs your attention right now.',
                style: context.textTheme3.bodySmall!.muted3(context),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.tint,
    this.detail,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color tint;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: SdContentPaddingV3.card,
      child: Row(
        children: <Widget>[
          SdIconTileV3(icon: icon, tint: tint),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: context.textTheme3.bodySmall!.muted3(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          // The count is the point of the row, so it is set at title weight
          // in the tint rather than tucked into a badge.
          Text(
            '$count',
            style: context.textTheme3.titleLarge!.tabular3.copyWith(
              color: tint,
            ),
          ),
          SizedBox(width: SdSpacingConstant.w4),
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

/// The last few orders (plan §6).
///
/// Orders rather than a generic audit feed: the audit log is written by Cloud
/// Functions and does not exist yet, and a seller checking Home wants to know
/// what sold, not that someone edited a SKU. It becomes the real activity
/// stream when `activity/` is populated.
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  /// Three rows. Enough to answer "what happened since I last looked" without
  /// turning Home into a second Orders screen.
  static const int maxRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Order> orders =
        ref.watch(ordersProvider).value ?? const <Order>[];
    final List<Order> recent = orders.take(maxRows).toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: SdCardV3(
        padding: EdgeInsets.zero,
        child: Column(
          children: <Widget>[
            for (int i = 0; i < recent.length; i++) ...<Widget>[
              _ActivityRow(order: recent[i]),
              if (i != recent.length - 1)
                Padding(
                  padding: EdgeInsets.only(
                    left:
                        SdSpacingConstant.w16 +
                        SdIconTileSizeV3.small.box +
                        SdSpacingConstant.w12,
                  ),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: context.sdTheme3.divider,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final Money? profit = order.profit().netProfit;

    return Padding(
      padding: SdContentPaddingV3.row,
      child: Row(
        children: <Widget>[
          SdIconTileV3(
            icon: Symbols.shopping_bag_rounded,
            tint: context.sdTheme3.textSecondary,
            size: SdIconTileSizeV3.small,
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  order.lines.isEmpty
                      ? 'Order ${order.id}'
                      : order.lines.first.title,
                  style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  order.marketplace.displayName,
                  style: context.textTheme3.bodySmall!.muted3(context),
                ),
              ],
            ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                context.money(order.salePrice),
                style: context.textTheme3.bodyMedium!.semiBold3.tabular3
                    .copyWith(color: context.sdTheme3.textPrimary),
              ),
              Text(
                context.money(profit),
                style: context.textTheme3.bodySmall!.tabular3.copyWith(
                  color: profit == null
                      ? context.sdTheme3.textTertiary
                      : profit.isNegative
                      ? context.sdTheme3.loss
                      : context.sdTheme3.profit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Profit as a filled hero, then three quiet tiles.
class _PerformanceBlock extends ConsumerWidget {
  const _PerformanceBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsSummary summary = ref.watch(analyticsSummaryProvider);
    final bool isDark = context.isDark3;
    final bool isLoss = summary.netProfit?.isNegative ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: Column(
        children: <Widget>[
          SdHeroStatV3(
            label: 'Net profit',
            value: summary.netProfit == null
                ? null
                : context.money(summary.netProfit),
            // A red hero card is the app saying something is wrong, so it is
            // driven by the sign of the number and never chosen for looks.
            gradient: isLoss
                ? AppColors.lossRamp(isDark: isDark)
                : AppColors.profitRamp(isDark: isDark),
            foreground: Colors.white,
            icon: Symbols.trending_up_rounded,
            caption: summary.isProfitComplete
                ? 'Margin ${context.percent(summary.margin)} · '
                      '${summary.orderCount} orders'
                : 'Partial — some item costs are missing',
            trailing: summary.isProfitComplete
                ? null
                : const SdBadgeV3(
                    label: 'Partial',
                    tone: SdBadgeToneV3.warning,
                    icon: Symbols.info_rounded,
                  ),
            onTap: () => context.go(AppRoutes.analytics),
          ),
          SizedBox(height: SdContentPaddingV3.listItemGap),
          // No icons on these three. At a third of the width the glyph costs
          // about 26px, which is exactly what turned "Revenue" into
          // "Reven…" — and the label is the tile's identity, so the label
          // wins.
          Row(
            children: <Widget>[
              Expanded(
                child: SdStatTileV3(
                  label: 'Revenue',
                  value: summary.revenue == null
                      ? null
                      : context.money(summary.revenue, compact: true),
                ),
              ),
              SizedBox(width: SdContentPaddingV3.listItemGap),
              Expanded(
                child: SdStatTileV3(
                  label: 'Sold',
                  value: '${summary.unitsSold}',
                ),
              ),
              SizedBox(width: SdContentPaddingV3.listItemGap),
              Expanded(
                child: SdStatTileV3(
                  label: 'Stock',
                  value: summary.inventoryValue == null
                      ? null
                      : context.money(summary.inventoryValue, compact: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
