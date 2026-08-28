import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/analytics_summary.dart';
import '../../../providers.dart';
import '../../widgets/metric_card.dart';

/// Marketplace analytics (plan §9) — where the money actually comes from.
///
/// **The fee rate shown is what the platform really took**, computed from the
/// fees on the orders — not `Marketplace.estimatedFeeRate`, which is a
/// planning number for the buy calculator and must never be presented as
/// accounting.
///
/// A platform whose orders have no recorded fees shows `—` for its rate. That
/// is the honest answer, and it is also a prompt: the fee is on the order's
/// "Fees and payout" sheet.
class AnalyticsMarketplaceScreen extends ConsumerWidget {
  const AnalyticsMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MarketplacePerformance> rows = ref.watch(
      marketplacePerformanceProvider,
    );

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.analyticsByMarketplace),
      body: rows.isEmpty
          ? SdEmptyStateV3(
              icon: AppIconConstant.hub,
              title: context.l10n.analyticsNothingHasSoldYet,
              message: context.l10n.analyticsRecordASaleAndThisRanks,
            )
          : ListView(
              padding: SdContentPaddingV3.screen(context),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                for (final MarketplacePerformance row in rows) ...<Widget>[
                  MetricCard(
                    title: row.marketplace.displayName,
                    rows: <Widget>[
                      MetricRow(
                        label: context.l10n.commonRevenue,
                        value: context.money(row.revenue),
                        isEmphasis: true,
                      ),
                      MetricRow(
                        label: context.l10n.orderProfitPrefix,
                        value: context.money(row.profit),
                        valueColor: row.profit == null
                            ? null
                            : row.profit!.isNegative
                            ? context.sdTheme3.loss
                            : context.sdTheme3.profit,
                      ),
                      MetricRow(
                        label: context.l10n.commonFees,
                        value: context.money(row.fees),
                      ),
                      MetricRow(
                        label: context.l10n.analyticsFeeRate,
                        value: context.percent(row.feeRate, decimals: 1),
                        caption: 'What this platform actually took',
                      ),
                      MetricRow(
                        label: context.l10n.commonOrders,
                        value: '${row.orderCount}',
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
