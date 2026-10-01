import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_filter_strip.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_marketplace_tag.dart';
import '../../../../../core/widgets/app_profit_hero.dart';
import '../../../../../core/widgets/app_section.dart';
import '../../../domain/entities/analytics_summary.dart';
import '../../../domain/entities/trend_bucket.dart';
import '../../../domain/enums/analytics_period.dart';
import '../../../domain/services/analytics_period_window.dart';
import '../../../providers.dart';

part 'analytics_screen_drill_downs.dart';
part 'analytics_screen_marketplace_breakdown.dart';
part 'analytics_screen_marketplace_row.dart';
part 'analytics_screen_period_strip.dart';
part 'analytics_screen_profit_statement.dart';
part 'analytics_screen_statement_row.dart';
part 'analytics_screen_trend.dart';

/// Analytics — "how is my business performing?".
///
/// Every figure is derived from the rows on read (hard rule 3), so correcting
/// a fee on one order corrects every total here at once.
///
/// **The period strip windows the hero, the trend and the statement.** The
/// marketplace ranking and the drill-downs stay all-time, as their own
/// screens are.
///
/// **A figure this screen cannot derive renders as `—`, never as zero**, and
/// the profit card says so out loud when some costs are missing rather than
/// presenting a partial number as the whole truth.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsSummary summary = ref.watch(periodSummaryProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.navAnalytics),
      // The strip sits above the list, not in it, so it stays put while the
      // figures scroll — the Orders layout.
      body: Column(
        // Stretched, or a strip whose chips all fit centres itself.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          const _PeriodStrip(),
          SizedBox(height: SdContentPaddingV3.topGap),
          Expanded(
            child: ListView(
              padding: SdContentPaddingV3.screen(context, floatingNav: true),
              children: <Widget>[
                // The headline first, then how it moved, then the
                // subtraction that produced it.
                AppProfitHero(summary: summary),
                const _ProfitTrend(),
                _ProfitStatement(summary: summary),
                const _MarketplaceBreakdown(),
                const _DrillDowns(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
