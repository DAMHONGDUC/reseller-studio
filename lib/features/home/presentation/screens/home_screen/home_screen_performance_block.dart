part of 'home_screen.dart';

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
