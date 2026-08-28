import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../inventory/providers.dart';
import '../../../domain/entities/analytics_breakdowns.dart';
import '../../../providers.dart';
import '../../widgets/metric_card.dart';

/// Category analytics (plan §9) — which kinds of stock are worth buying more
/// of.
///
/// **Items with no category are absent rather than lumped into an "Other"
/// row.** That row would be the biggest one on the screen in most workspaces
/// and would say nothing except that the seller has not categorised their
/// stock — which is a nag, not an insight.
///
/// Revenue is joined from the orders. A category's asking prices say what the
/// seller hoped for; only the sales say what it is worth.
class AnalyticsCategoriesScreen extends ConsumerWidget {
  const AnalyticsCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CategoryPerformance> rows = ref.watch(
      categoryPerformanceProvider,
    );
    final Map<String, String> names = ref.watch(categoryNamesProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.analyticsByCategory),
      body: rows.isEmpty
          ? SdEmptyStateV3(
              icon: AppIconConstant.category,
              title: context.l10n.analyticsNothingIsCategorisedYet,
              message: context.l10n.analyticsPutYourItemsIntoCategoriesAnd,
            )
          : ListView(
              padding: SdContentPaddingV3.screen(context),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                for (final CategoryPerformance row in rows) ...<Widget>[
                  MetricCard(
                    title: names[row.categoryId] ?? row.categoryId,
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
                        label: context.l10n.commonRoi,
                        value: context.percent(row.roi),
                        caption: 'Return on what these items cost',
                      ),
                      MetricRow(
                        label: context.l10n.commonSellThrough,
                        value: context.percent(row.sellThrough, decimals: 1),
                        caption: '${row.soldCount} of ${row.itemCount} sold',
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
