part of 'analytics_screen.dart';

/// The six breakdowns the plan asks for (§9), as one list.
///
/// **The tab keeps the overview; each of these answers one question.** Putting
/// all six on the tab would make the screen a report nobody reads, and the
/// plan's own hierarchy — one loud element, then quiet ones — cannot survive
/// six equally weighted sections.
class _DrillDowns extends StatelessWidget {
  const _DrillDowns();

  @override
  Widget build(BuildContext context) => AppListCard(
    children: <Widget>[
      AppListRow(
        title: context.l10n.analyticsSales,
        subtitle: context.l10n.analyticsRevenueOrdersUnitsAverages,
        icon: AppIconConstant.pointOfSale,
        onTap: () => context.push(AppRoutes.analyticsSales),
      ),
      AppListRow(
        title: context.l10n.orderProfitPrefix,
        subtitle: context.l10n.analyticsTheFullStatementLineByLine,
        icon: AppIconConstant.savings,
        onTap: () => context.push(AppRoutes.analyticsProfit),
      ),
      AppListRow(
        title: context.l10n.workflowInventory,
        subtitle: context.l10n.analyticsValueSellThroughDaysToSell,
        icon: AppIconConstant.inventory,
        onTap: () => context.push(AppRoutes.analyticsInventory),
      ),
      AppListRow(
        title: context.l10n.marketplacesTitle,
        subtitle: context.l10n.analyticsWhatEachPlatformReallyTook,
        icon: AppIconConstant.hub,
        onTap: () => context.push(AppRoutes.analyticsMarketplace),
      ),
      AppListRow(
        title: context.l10n.categoriesTitle,
        subtitle: context.l10n.analyticsWhichKindsOfStockEarn,
        icon: AppIconConstant.category,
        onTap: () => context.push(AppRoutes.analyticsCategories),
      ),
      AppListRow(
        title: context.l10n.analyticsSources,
        subtitle: context.l10n.analyticsWhereToGoBackToRanked,
        icon: AppIconConstant.storefront,
        onTap: () => context.push(AppRoutes.analyticsSources),
      ),
    ],
  );
}
