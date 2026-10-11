part of 'home_screen.dart';

/// Profit as a filled hero, then three quiet tiles.
class _PerformanceBlock extends ConsumerStatefulWidget {
  const _PerformanceBlock();

  @override
  ConsumerState<_PerformanceBlock> createState() => _PerformanceBlockState();
}

/// The profit hero always; the three quiet tiles behind Show more, so the
/// block is a glance until the seller asks for more (`docs/UI_POLISH_PLAN.md`).
class _PerformanceBlockState extends ConsumerState<_PerformanceBlock> {
  bool _more = false;

  @override
  Widget build(BuildContext context) {
    final AnalyticsSummary summary = ref.watch(analyticsSummaryProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: Column(
        children: <Widget>[
          AppProfitHero(
            summary: summary,
            onTap: () => context.go(AppRoutes.analytics),
          ),
          AnimatedSize(
            duration: SdMotionV3.of(context, SdMotionV3.normal),
            curve: SdMotionV3.emphasized,
            alignment: Alignment.topCenter,
            child: _more
                ? Padding(
                    padding: EdgeInsets.only(
                      top: SdContentPaddingV3.listItemGap,
                    ),
                    child: _Tiles(summary: summary),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SdButtonV3(
              variant: SdButtonVariantV3.text,
              label: _more
                  ? context.l10n.homeShowLess
                  : context.l10n.homeShowMore,
              size: SdButtonSizeV3.small,
              onPressed: () => setState(() => _more = !_more),
            ),
          ),
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
  );
}
