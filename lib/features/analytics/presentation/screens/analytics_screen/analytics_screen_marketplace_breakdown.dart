part of 'analytics_screen.dart';

/// Revenue share per platform, as a bar per row.
///
/// A bar rather than a pie: comparing lengths against a shared baseline is
/// something people do accurately, and comparing angles is not — and the
/// question here is "which platform earns most", which is a comparison.
class _MarketplaceBreakdown extends ConsumerWidget {
  const _MarketplaceBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MarketplacePerformance> rows = ref.watch(
      marketplacePerformanceProvider,
    );

    if (rows.isEmpty) {
      return SdEmptyStateV3(
        icon: AppIconConstant.barChart,
        title: context.l10n.analyticsNoSalesYet,
        message: context.l10n.analyticsMarketplacePerformanceAppearsOnceYouHave,
      );
    }

    final int maxRevenue = rows
        .map((MarketplacePerformance row) => row.revenue.minor)
        .reduce((int a, int b) => a > b ? a : b);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: SdCardV3(
        child: Column(
          children: <Widget>[
            for (int i = 0; i < rows.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == rows.length - 1 ? 0 : SdSpacingConstant.h16,
                ),
                child: _MarketplaceRow(
                  row: rows[i],
                  maxRevenue: maxRevenue,
                  // The marketplace's own hue, not a chart series colour: a
                  // platform that is amber on an order card and blue on a bar
                  // is two colours for one thing.
                  color: AppMarketplaceDot.hueOf(
                    ref,
                    rows[i].marketplaceId,
                  ).of(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
