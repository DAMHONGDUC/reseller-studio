import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/router/app_routes.dart';

/// One link in the lifecycle this app exists to serve.
///
/// **The label is not here.** A label is a user-facing string (hard rule 7),
/// so the step carries a [kind] and `WorkflowLabel` turns it into words.
class WorkflowStep {
  const WorkflowStep({
    required this.kind,
    required this.icon,
    required this.route,
  });

  final WorkflowKind kind;
  final IconData icon;

  /// Where this step is actually done. **A step opens the part of the app
  /// that performs it** — the diagram is a way in, not a picture. A screen
  /// that explains a workflow without leading into it is the kind of screen
  /// `CLAUDE.md` says will be redesigned.
  final String route;
}

enum WorkflowKind {
  source,
  purchase,
  inventory,
  list,
  sell,
  ship,
  profit,
  analyze,
  sourceBetter,
}

/// The chain the whole product is judged against, as data.
///
/// It is written once in `CLAUDE.md` as a line of text:
///
/// ```text
/// SOURCE → PURCHASE → INVENTORY → LIST → SELL → SHIP → PROFIT → ANALYZE →
/// SOURCE BETTER
/// ```
///
/// This is the same chain, rendered for the seller rather than for whoever is
/// writing the code. **It is a loop, not a list** — the last step feeds the
/// first, which is the whole argument for keeping cost and source attached to
/// every item.
final class WorkflowConstant {
  static const List<WorkflowStep> steps = <WorkflowStep>[
    WorkflowStep(
      kind: WorkflowKind.source,
      icon: Symbols.travel_explore_rounded,
      route: AppRoutes.sources,
    ),
    WorkflowStep(
      kind: WorkflowKind.purchase,
      icon: Symbols.shopping_bag_rounded,
      route: AppRoutes.purchases,
    ),
    WorkflowStep(
      kind: WorkflowKind.inventory,
      icon: Symbols.inventory_2_rounded,
      route: AppRoutes.inventory,
    ),
    WorkflowStep(
      kind: WorkflowKind.list,
      icon: Symbols.sell_rounded,
      route: AppRoutes.listings,
    ),
    WorkflowStep(
      kind: WorkflowKind.sell,
      icon: Symbols.point_of_sale_rounded,
      route: AppRoutes.orders,
    ),
    WorkflowStep(
      kind: WorkflowKind.ship,
      icon: Symbols.local_shipping_rounded,
      route: AppRoutes.shippingQueue,
    ),
    WorkflowStep(
      kind: WorkflowKind.profit,
      icon: Symbols.savings_rounded,
      route: AppRoutes.analyticsProfit,
    ),
    WorkflowStep(
      kind: WorkflowKind.analyze,
      icon: Symbols.bar_chart_rounded,
      route: AppRoutes.analytics,
    ),
    WorkflowStep(
      kind: WorkflowKind.sourceBetter,
      icon: Symbols.restart_alt_rounded,
      route: AppRoutes.analyticsSources,
    ),
  ];
}

/// The words for a workflow step.
final class WorkflowLabel {
  static String title(BuildContext context, WorkflowKind kind) =>
      switch (kind) {
        WorkflowKind.source => context.l10n.workflowSource,
        WorkflowKind.purchase => context.l10n.workflowPurchase,
        WorkflowKind.inventory => context.l10n.workflowInventory,
        WorkflowKind.list => context.l10n.workflowList,
        WorkflowKind.sell => context.l10n.workflowSell,
        WorkflowKind.ship => context.l10n.workflowShip,
        WorkflowKind.profit => context.l10n.workflowProfit,
        WorkflowKind.analyze => context.l10n.workflowAnalyze,
        WorkflowKind.sourceBetter => context.l10n.workflowSourceBetter,
      };

  static String detail(BuildContext context, WorkflowKind kind) =>
      switch (kind) {
        WorkflowKind.source => context.l10n.workflowSourceDetail,
        WorkflowKind.purchase => context.l10n.workflowPurchaseDetail,
        WorkflowKind.inventory => context.l10n.workflowInventoryDetail,
        WorkflowKind.list => context.l10n.workflowListDetail,
        WorkflowKind.sell => context.l10n.workflowSellDetail,
        WorkflowKind.ship => context.l10n.workflowShipDetail,
        WorkflowKind.profit => context.l10n.workflowProfitDetail,
        WorkflowKind.analyze => context.l10n.workflowAnalyzeDetail,
        WorkflowKind.sourceBetter => context.l10n.workflowSourceBetterDetail,
      };
}
