import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../sourcing/providers.dart';
import '../../widgets/metric_card.dart';

/// Source analytics (plan §9) — the last step of the product's lifecycle.
///
/// **This is the screen the whole `Source → Purchase → Item` chain exists
/// for.** Every other analytics screen says what happened; this one says where
/// to go next Saturday. Without it the app can tell a seller what sold and not
/// where to find more of it.
///
/// Sorted by ROI rather than by revenue: the shop that returns 180% on £40 is
/// a better place to spend a morning than the one returning 20% on £400.
class AnalyticsSourcesScreen extends ConsumerWidget {
  const AnalyticsSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String> names = ref.watch(sourceNamesProvider);

    final List<SourcePerformance> rows =
        List<SourcePerformance>.of(ref.watch(sourcePerformanceProvider))
          ..sort((SourcePerformance a, SourcePerformance b) {
            final double? left = a.roi;
            final double? right = b.roi;

            // Sources with no answer sort last: they are not bad, they are
            // unknown, and putting them at the top would bury the ones that
            // have actually been measured.
            if (left == null && right == null) return 0;
            if (left == null) return 1;
            if (right == null) return -1;

            return right.compareTo(left);
          });

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.analyticsBySource),
      body: rows.isEmpty
          ? SdEmptyStateV3(
              icon: AppIconConstant.storefront,
              title: context.l10n.analyticsNoSourcesYet,
              message: context.l10n.analyticsRecordWhereStockComesFromAnd,
            )
          : ListView(
              padding: SdContentPaddingV3.screen(context),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                for (final SourcePerformance row in rows) ...<Widget>[
                  MetricCard(
                    title: names[row.sourceId] ?? row.sourceId,
                    rows: <Widget>[
                      MetricRow(
                        label: context.l10n.commonRoi,
                        value: context.percent(row.roi),
                        isEmphasis: true,
                        valueColor: row.roi == null
                            ? null
                            : row.roi! < 0
                            ? context.sdTheme3.loss
                            : context.sdTheme3.profit,
                      ),
                      MetricRow(
                        label: context.l10n.analyticsSpent,
                        value: context.money(row.spend),
                      ),
                      MetricRow(
                        label: context.l10n.commonRevenue,
                        value: context.money(row.revenue),
                      ),
                      MetricRow(
                        label: context.l10n.orderProfitPrefix,
                        value: context.money(row.profit),
                      ),
                      MetricRow(
                        label: context.l10n.commonItems,
                        value: '${row.itemsSold} / ${row.itemsBought}',
                        caption: 'Sold of bought',
                      ),
                    ],
                  ),
                  SizedBox(height: SdContentPaddingV3.sectionGap),
                ],
              ],
            ),
    );
  }
}
