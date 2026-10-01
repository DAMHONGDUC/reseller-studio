part of 'home_screen.dart';

/// Profit as a filled hero, then three quiet tiles.
class _PerformanceBlock extends ConsumerWidget {
  const _PerformanceBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsSummary summary = ref.watch(analyticsSummaryProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: Column(
        children: <Widget>[
          AppProfitHero(
            summary: summary,
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
                  label: context.l10n.commonRevenue,
                  value: summary.revenue == null
                      ? null
                      : context.money(summary.revenue, compact: true),
                ),
              ),
              SizedBox(width: SdContentPaddingV3.listItemGap),
              Expanded(
                child: SdStatTileV3(
                  label: context.l10n.itemStatusSold,
                  value: '${summary.unitsSold}',
                ),
              ),
              SizedBox(width: SdContentPaddingV3.listItemGap),
              Expanded(
                child: SdStatTileV3(
                  label: context.l10n.homeStock,
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
