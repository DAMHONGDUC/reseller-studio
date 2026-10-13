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
          _Tiles(summary: summary),
        ],
      ),
    );
  }
}

/// Revenue, units sold and stock value — the quiet half of Performance.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      // No icons on these three: at a third of the width the glyph turned
      // "Revenue" into "Reven…", and the label is the tile's identity.
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
  );
}
