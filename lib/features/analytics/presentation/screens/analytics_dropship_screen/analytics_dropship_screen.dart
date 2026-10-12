import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../sourcing/providers.dart';
import '../../../domain/services/dropship_performance.dart';
import '../../../providers.dart';
import '../../widgets/metric_card.dart';

/// Dropship analytics (`docs/DROPSHIPPING_PLAN.md`, §6): the business split
/// by who ships, products ranked best first — so the losing end is where a
/// product to drop is found — and how fast each supplier dispatches.
///
/// Profit here is gross, revenue less cost, as the category breakdown reads
/// it; an unknown cost leaves `—` (hard rule 5).
class AnalyticsDropshipScreen extends ConsumerWidget {
  const AnalyticsDropshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ({FulfilmentFigures stocked, FulfilmentFigures dropship}) split = ref
        .watch(fulfilmentSplitProvider);
    final List<DropshipProductPerformance> products = ref.watch(
      dropshipProductsProvider,
    );
    final List<SupplierShipTime> shipTimes = ref.watch(
      supplierShipTimesProvider,
    );
    final Map<String, String> names = ref.watch(sourceNamesProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.analyticsDropship),
      body: products.isEmpty
          ? SdEmptyStateV3(
              icon: AppIconConstant.localShipping,
              title: context.l10n.analyticsDropshipEmptyTitle,
              message: context.l10n.analyticsDropshipEmptyBody,
            )
          : ListView(
              padding: SdContentPaddingV3.screen(context),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                _SplitCard(
                  title: context.l10n.fulfilmentStocked,
                  figures: split.stocked,
                ),
                SizedBox(height: SdContentPaddingV3.listItemGap),
                _SplitCard(
                  title: context.l10n.fulfilmentDropship,
                  figures: split.dropship,
                ),
                SdSectionHeaderV3(
                  title: context.l10n.analyticsDropshipProducts,
                ),
                for (final DropshipProductPerformance row
                    in products) ...<Widget>[
                  MetricCard(
                    title: row.title,
                    rows: <Widget>[
                      MetricRow(
                        label: context.l10n.analyticsUnitsSold,
                        value: '${row.unitsSold}',
                      ),
                      MetricRow(
                        label: context.l10n.commonRevenue,
                        value: context.money(row.revenue),
                      ),
                      _ProfitRow(profit: row.profit),
                    ],
                  ),
                  SizedBox(height: SdContentPaddingV3.listItemGap),
                ],
                if (shipTimes.isNotEmpty) ...<Widget>[
                  SdSectionHeaderV3(
                    title: context.l10n.analyticsSupplierShipTime,
                  ),
                  MetricCard(
                    title: context.l10n.suppliersTitle,
                    rows: <Widget>[
                      for (final SupplierShipTime row in shipTimes)
                        MetricRow(
                          label: names[row.sourceId] ?? row.sourceId,
                          value: context.l10n.analyticsDaysAverage(
                            row.averageDays.toStringAsFixed(1),
                          ),
                          caption: context.l10n.analyticsShipments(
                            row.shipments,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({required this.title, required this.figures});

  final String title;
  final FulfilmentFigures figures;

  @override
  Widget build(BuildContext context) => MetricCard(
    title: title,
    rows: <Widget>[
      MetricRow(
        label: context.l10n.analyticsUnitsSold,
        value: '${figures.lines}',
      ),
      MetricRow(
        label: context.l10n.commonRevenue,
        value: context.money(figures.revenue),
      ),
      _ProfitRow(profit: figures.profit),
    ],
  );
}

class _ProfitRow extends StatelessWidget {
  const _ProfitRow({required this.profit});

  final Money? profit;

  @override
  Widget build(BuildContext context) {
    final Money? value = profit;

    return MetricRow(
      label: context.l10n.orderProfitPrefix,
      value: context.money(value),
      valueColor: value == null
          ? null
          : value.isNegative
          ? context.sdTheme3.loss
          : context.sdTheme3.profit,
    );
  }
}
