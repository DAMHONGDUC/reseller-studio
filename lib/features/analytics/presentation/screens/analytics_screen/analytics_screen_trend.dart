part of 'analytics_screen.dart';

/// Revenue and profit, a pair of bars per day, week or month.
///
/// **A bucket with an unknown profit draws revenue alone** — a profit bar
/// summed over half the sales would look like the whole of them (hard
/// rule 5). The caption says the bars are before overheads, so they are not
/// read as pieces of the net profit above.
class _ProfitTrend extends ConsumerWidget {
  const _ProfitTrend();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TrendBucket> buckets = ref.watch(profitTrendProvider);
    final TrendGrain grain = AnalyticsPeriodWindow.grainOf(
      ref.watch(analyticsPeriodProvider),
      custom: ref.watch(analyticsCustomRangeProvider),
    );

    return AppSection(
      title: context.l10n.analyticsTrend,
      subtitle: context.l10n.analyticsTrendCaption,
      child: buckets.isEmpty
          ? SdEmptyStateV3(
              variant: SdEmptyStateVariantV3.inline,
              icon: AppIconConstant.barChart,
              title: context.l10n.analyticsTrendEmpty,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _TrendChart(buckets: buckets, grain: grain),
                SizedBox(height: SdSpacingConstant.h12),
                const _TrendLegend(),
              ],
            ),
    );
  }
}

/// The bars themselves, drawn by `fl_chart`.
///
/// **They grow in from the axis the first time they are drawn, and move to
/// a new period rather than jumping** (`docs/UI_POLISH_PLAN.md`) — the
/// chart's own tween, on `SdMotionV3` timing, and none under reduced motion.
class _TrendChart extends StatefulWidget {
  const _TrendChart({required this.buckets, required this.grain});

  /// Revenue is the brand colour washed out, profit the brand colour itself:
  /// one hue reads as one subject, and the wash holds up on a dark page where
  /// the tonal container colour all but disappeared.
  static Color revenueColor(BuildContext context) =>
      context.colorScheme3.primary.withValues(alpha: 0.32);

  /// The chart's own height — what it is, not configuration about it.
  static double get height => SdSpacingConstant.h160;

  final List<TrendBucket> buckets;
  final TrendGrain grain;

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> {
  /// False for the first frame, so the bars have a zero to grow from.
  bool _drawn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) setState(() => _drawn = true);
    });
  }

  /// The axis label for a bucket: a weekday, a date or a month.
  static String _label(DateTime start, TrendGrain grain, String locale) =>
      switch (grain) {
        TrendGrain.day => DateTimeUtils.weekdayShort(start, locale: locale),
        TrendGrain.week => DateTimeUtils.shortDate(start, locale: locale),
        TrendGrain.month => DateTimeUtils.monthShort(start, locale: locale),
      };

  @override
  Widget build(BuildContext context) {
    final List<TrendBucket> buckets = widget.buckets;
    final TrendGrain grain = widget.grain;
    final double grow = _drawn ? 1 : 0;
    final Color revenue = _TrendChart.revenueColor(context);
    final Color profit = context.colorScheme3.primary;
    final Color loss = context.sdTheme3.loss;
    final String locale = context.localeTag;
    final double barWidth = SdSpacingConstant.w8;
    final double lowest = buckets
        .map((TrendBucket b) => b.profit?.major ?? 0)
        .fold(0, (double low, double v) => v < low ? v : low);

    return Semantics(
      label: context.l10n.analyticsTrendSemantics,
      excludeSemantics: true,
      child: SizedBox(
        height: _TrendChart.height,
        child: BarChart(
          duration: SdMotionV3.of(context, SdMotionV3.slow),
          curve: SdMotionV3.standard,
          BarChartData(
            minY: lowest * grow,
            barTouchData: BarTouchData(enabled: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (double value) => FlLine(
                color: context.sdTheme3.chartGrid,
                strokeWidth: SdSpacingConstant.w2 / 2,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: SdSpacingConstant.h24,
                  getTitlesWidget: (double value, TitleMeta meta) =>
                      SideTitleWidget(
                        meta: meta,
                        child: Text(
                          _label(buckets[value.toInt()].start, grain, locale),
                          style: context.textTheme3.labelSmall!.faint3(context),
                        ),
                      ),
                ),
              ),
            ),
            barGroups: <BarChartGroupData>[
              for (int i = 0; i < buckets.length; i++)
                BarChartGroupData(
                  x: i,
                  barsSpace: SdSpacingConstant.w2,
                  barRods: <BarChartRodData>[
                    BarChartRodData(
                      toY: buckets[i].revenue.major * grow,
                      color: revenue,
                      width: barWidth,
                      borderRadius: SdRadiusV3.chipAll,
                    ),
                    BarChartRodData(
                      toY: (buckets[i].profit?.major ?? 0) * grow,
                      color: (buckets[i].profit?.isNegative ?? false)
                          ? loss
                          : profit,
                      width: barWidth,
                      borderRadius: SdRadiusV3.chipAll,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which bar is which — a swatch is never the only way to tell.
class _TrendLegend extends StatelessWidget {
  const _TrendLegend();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: SdSpacingConstant.w16,
    runSpacing: SdSpacingConstant.h4,
    children: <Widget>[
      _LegendKey(
        color: _TrendChart.revenueColor(context),
        label: context.l10n.commonRevenue,
      ),
      _LegendKey(
        color: context.colorScheme3.primary,
        label: context.l10n.itemProfit,
      ),
    ],
  );
}

class _LegendKey extends StatelessWidget {
  const _LegendKey({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: SdSpacingConstant.w12,
        height: SdSpacingConstant.w12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: SdRadiusV3.chipAll,
        ),
      ),
      SizedBox(width: SdSpacingConstant.w6),
      Text(label, style: context.textTheme3.bodySmall!.muted3(context)),
    ],
  );
}
