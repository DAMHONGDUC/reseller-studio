import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/analytics_breakdowns.dart';
import '../../../providers.dart';
import '../../widgets/metric_card.dart';

/// Inventory analytics (plan §9) — what is being held, and how fast it moves.
///
/// **Inventory value is at cost, not at asking price.** Retail-value inventory
/// is a number that flatters the seller and is the wrong one for insurance and
/// tax, which is what the figure is actually used for.
///
/// Average days to sell counts only the items that recorded both a listing
/// date and a sale date. An item sold straight off the shelf never had a
/// listing date and cannot answer the question — including it as zero would
/// flatter the average, which is the opposite of useful.
class AnalyticsInventoryScreen extends ConsumerWidget {
  const AnalyticsInventoryScreen({super.key});

  /// One decimal on a day count: "43.5 days" is a real distinction between two
  /// months of stock, where "43" and "44" are not worth the precision.
  static const int dayDecimals = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryMetrics metrics = ref.watch(inventoryMetricsProvider);
    final String dash = context.l10n.emptyValuePlaceholder;

    return SdScaffoldV3(
      appBar: const SdAppBarV3(title: 'Inventory'),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          MetricCard(
            title: 'What you hold',
            rows: <Widget>[
              MetricRow(
                label: 'Inventory value',
                value: context.money(metrics.value),
                caption: 'At cost, not at asking price',
                isEmphasis: true,
              ),
              MetricRow(
                label: 'Items on hand',
                value: '${metrics.onHandCount}',
              ),
              MetricRow(label: 'Listed', value: '${metrics.listedCount}'),
              MetricRow(
                label: 'Stale',
                value: '${metrics.staleCount}',
                caption: 'Listed, and listed a long time ago',
                valueColor: metrics.staleCount > 0
                    ? context.sdTheme3.warning
                    : null,
              ),
            ],
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          MetricCard(
            title: 'How fast it moves',
            rows: <Widget>[
              MetricRow(label: 'Items sold', value: '${metrics.soldCount}'),
              MetricRow(
                label: 'Sell-through',
                value: context.percent(metrics.sellThrough, decimals: 1),
                caption: 'Sold as a share of everything ever held',
              ),
              MetricRow(
                label: 'Average days to sell',
                value: _days(metrics.averageDaysToSell, dash),
                caption: 'From listing to sale',
              ),
              MetricRow(
                label: 'Average age of stock',
                value: _days(metrics.averageAgeDays, dash),
                caption: 'How long what you hold has been sitting',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// `43.5 days`, or the em dash when nothing can answer it (hard rule 5).
  static String _days(double? value, String dash) {
    if (value == null) return dash;

    return '${value.toStringAsFixed(dayDecimals)} days';
  }
}
