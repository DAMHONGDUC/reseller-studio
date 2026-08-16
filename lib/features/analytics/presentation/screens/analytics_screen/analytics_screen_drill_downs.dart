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
        title: 'Sales',
        subtitle: 'Revenue, orders, units, averages',
        icon: Symbols.point_of_sale_rounded,
        onTap: () => context.push(AppRoutes.analyticsSales),
      ),
      AppListRow(
        title: 'Profit',
        subtitle: 'The full statement, line by line',
        icon: Symbols.savings_rounded,
        onTap: () => context.push(AppRoutes.analyticsProfit),
      ),
      AppListRow(
        title: 'Inventory',
        subtitle: 'Value, sell-through, days to sell, stale stock',
        icon: Symbols.inventory_2_rounded,
        onTap: () => context.push(AppRoutes.analyticsInventory),
      ),
      AppListRow(
        title: 'Marketplaces',
        subtitle: 'What each platform really took',
        icon: Symbols.hub_rounded,
        onTap: () => context.push(AppRoutes.analyticsMarketplace),
      ),
      AppListRow(
        title: 'Categories',
        subtitle: 'Which kinds of stock earn',
        icon: Symbols.category_rounded,
        onTap: () => context.push(AppRoutes.analyticsCategories),
      ),
      AppListRow(
        title: 'Sources',
        subtitle: 'Where to go back to — ranked by ROI',
        icon: Symbols.storefront_rounded,
        onTap: () => context.push(AppRoutes.analyticsSources),
      ),
    ],
  );
}
