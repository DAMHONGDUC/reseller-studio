import 'package:flutter/widgets.dart';

import '../../core/constants/app_icon_constant.dart';
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
    this.isOptional = false,
  });

  final WorkflowKind kind;
  final IconData icon;

  /// Where this step is actually done. **A step opens the part of the app
  /// that performs it** — the diagram is a way in, not a picture. A screen
  /// that explains a workflow without leading into it is the kind of screen
  /// `CLAUDE.md` says will be redesigned.
  final String route;

  /// **Optional means the app never blocks on this step**, not that it does
  /// not matter. Requirements attach when a record *moves* rather than when it
  /// is created (hard rule 2), so a seller can skip listing, shipping and
  /// recording a source entirely and still get paid. Home's flow overview
  /// badges these, because a seller who thinks all nine are mandatory goes
  /// back to the spreadsheet.
  final bool isOptional;
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
      isOptional: true,
      icon: AppIconConstant.travelExplore,
      route: AppRoutes.sources,
    ),
    WorkflowStep(
      kind: WorkflowKind.purchase,
      isOptional: true,
      icon: AppIconConstant.shoppingBag,
      route: AppRoutes.purchases,
    ),
    WorkflowStep(
      kind: WorkflowKind.inventory,
      icon: AppIconConstant.inventory,
      route: AppRoutes.inventory,
    ),
    WorkflowStep(
      kind: WorkflowKind.list,
      isOptional: true,
      icon: AppIconConstant.sell,
      route: AppRoutes.listings,
    ),
    WorkflowStep(
      kind: WorkflowKind.sell,
      icon: AppIconConstant.pointOfSale,
      route: AppRoutes.orders,
    ),
    WorkflowStep(
      kind: WorkflowKind.ship,
      isOptional: true,
      icon: AppIconConstant.localShipping,
      route: AppRoutes.shippingQueue,
    ),
    WorkflowStep(
      kind: WorkflowKind.profit,
      icon: AppIconConstant.savings,
      route: AppRoutes.analyticsProfit,
    ),
    WorkflowStep(
      kind: WorkflowKind.analyze,
      isOptional: true,
      icon: AppIconConstant.barChart,
      route: AppRoutes.analytics,
    ),
    WorkflowStep(
      kind: WorkflowKind.sourceBetter,
      isOptional: true,
      icon: AppIconConstant.restartAlt,
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

  /// What the seller actually does at this step, in the order they do it.
  ///
  /// **Three lines each, and they name the screen.** Home's flow overview is
  /// the answer to "how do I use this app", and a one-line summary per step is
  /// a table of contents rather than an answer. Kept beside [detail] because
  /// they are the same fact at two lengths — the diagram shows one, the sheet
  /// shows both.
  static List<String> how(BuildContext context, WorkflowKind kind) =>
      switch (kind) {
        WorkflowKind.source => <String>[
          context.l10n.workflowSourceHow1,
          context.l10n.workflowSourceHow2,
          context.l10n.workflowSourceHow3,
        ],
        WorkflowKind.purchase => <String>[
          context.l10n.workflowPurchaseHow1,
          context.l10n.workflowPurchaseHow2,
          context.l10n.workflowPurchaseHow3,
        ],
        WorkflowKind.inventory => <String>[
          context.l10n.workflowInventoryHow1,
          context.l10n.workflowInventoryHow2,
          context.l10n.workflowInventoryHow3,
        ],
        WorkflowKind.list => <String>[
          context.l10n.workflowListHow1,
          context.l10n.workflowListHow2,
          context.l10n.workflowListHow3,
        ],
        WorkflowKind.sell => <String>[
          context.l10n.workflowSellHow1,
          context.l10n.workflowSellHow2,
          context.l10n.workflowSellHow3,
        ],
        WorkflowKind.ship => <String>[
          context.l10n.workflowShipHow1,
          context.l10n.workflowShipHow2,
          context.l10n.workflowShipHow3,
        ],
        WorkflowKind.profit => <String>[
          context.l10n.workflowProfitHow1,
          context.l10n.workflowProfitHow2,
          context.l10n.workflowProfitHow3,
        ],
        WorkflowKind.analyze => <String>[
          context.l10n.workflowAnalyzeHow1,
          context.l10n.workflowAnalyzeHow2,
          context.l10n.workflowAnalyzeHow3,
        ],
        WorkflowKind.sourceBetter => <String>[
          context.l10n.workflowSourceBetterHow1,
          context.l10n.workflowSourceBetterHow2,
          context.l10n.workflowSourceBetterHow3,
        ],
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
