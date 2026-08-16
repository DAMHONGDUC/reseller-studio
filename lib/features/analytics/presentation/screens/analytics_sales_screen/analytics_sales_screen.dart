import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/analytics_breakdowns.dart';
import '../../../providers.dart';
import '../../widgets/metric_card.dart';

/// Sales (plan §9) — what actually sold.
///
/// **Average order value and average selling price are both here, and they
/// are not the same number.** One is per order, the other per unit; they
/// agree only when every order has a single line. A seller who bundles needs
/// both — one says whether the pricing is right, the other whether the basket
/// is.
class AnalyticsSalesScreen extends ConsumerWidget {
  const AnalyticsSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SalesMetrics metrics = ref.watch(salesMetricsProvider);

    return SdScaffoldV3(
      appBar: const SdAppBarV3(title: 'Sales'),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          MetricCard(
            title: 'Volume',
            rows: <Widget>[
              MetricRow(
                label: 'Revenue',
                value: context.money(metrics.revenue),
                caption: 'After refunds',
                isEmphasis: true,
              ),
              MetricRow(label: 'Orders', value: '${metrics.orderCount}'),
              MetricRow(label: 'Units sold', value: '${metrics.unitsSold}'),
              MetricRow(
                label: 'Refunded',
                value: context.money(metrics.refunded),
              ),
            ],
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          MetricCard(
            title: 'Averages',
            rows: <Widget>[
              MetricRow(
                label: 'Average order value',
                value: context.money(metrics.averageOrderValue),
                caption: 'Revenue per order',
              ),
              MetricRow(
                label: 'Average selling price',
                value: context.money(metrics.averageSellingPrice),
                caption: 'Revenue per unit',
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            'Cancelled and refunded orders are left out. Counting either '
            'would make these figures disagree with your bank.',
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
        ],
      ),
    );
  }
}
