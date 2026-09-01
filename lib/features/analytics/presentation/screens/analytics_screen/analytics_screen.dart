import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_marketplace_tag.dart';
import '../../../domain/entities/analytics_summary.dart';
import '../../../providers.dart';

part 'analytics_screen_drill_downs.dart';
part 'analytics_screen_marketplace_breakdown.dart';
part 'analytics_screen_marketplace_row.dart';
part 'analytics_screen_profit_statement.dart';
part 'analytics_screen_statement_row.dart';

/// Analytics — "how is my business performing?".
///
/// Every figure is derived from the rows on read (hard rule 3), so correcting
/// a fee on one order corrects every total here at once.
///
/// **A figure this screen cannot derive renders as `—`, never as zero**, and
/// the profit card says so out loud when some costs are missing rather than
/// presenting a partial number as the whole truth.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsSummary summary = ref.watch(analyticsSummaryProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.navAnalytics),
      body: ListView(
        padding: SdContentPaddingV3.fullBleed(context, floatingNav: true),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          SdSectionHeaderV3(title: context.l10n.analyticsOverview, first: true),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: _ProfitStatement(summary: summary),
          ),
          SdSectionHeaderV3(
            title: context.l10n.analyticsByMarketplace,
            subtitle: context.l10n.analyticsWhereTheMoneyActuallyComesFrom,
          ),
          const _MarketplaceBreakdown(),
          SdSectionHeaderV3(
            title: context.l10n.analyticsGoDeeper,
            subtitle: context.l10n.analyticsTheSameFiguresOneQuestionAt,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: const _DrillDowns(),
          ),
        ],
      ),
    );
  }
}
