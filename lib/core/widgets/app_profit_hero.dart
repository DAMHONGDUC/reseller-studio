import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../features/analytics/domain/entities/analytics_summary.dart';
import '../constants/app_icon_constant.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';

/// Net profit as the one filled hero on a screen.
///
/// **Shared by Home and Analytics** so the two screens cannot disagree about
/// what the headline figure is or how a partial one is flagged.
///
/// - the ramp follows the sign of the number, never looks: a red hero is the
///   app saying something is wrong
/// - a partial figure says so in the caption and with a badge (hard rule 5's
///   spirit: a number that is not the whole truth must not pass for it)
class AppProfitHero extends StatelessWidget {
  const AppProfitHero({required this.summary, this.onTap, super.key});

  final AnalyticsSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark3;
    final bool isLoss = summary.netProfit?.isNegative ?? false;

    return SdHeroStatV3(
      label: context.l10n.commonNetProfit,
      value: summary.netProfit == null
          ? null
          : context.money(summary.netProfit),
      gradient: isLoss
          ? AppColors.lossRamp(isDark: isDark)
          : AppColors.profitRamp(isDark: isDark),
      foreground: Colors.white,
      icon: AppIconConstant.trendingUp,
      caption: summary.isProfitComplete
          ? '${context.l10n.analyticsMarginValue(context.percent(summary.margin))}'
                ' · ${context.l10n.analyticsOrderCount(summary.orderCount)}'
          : context.l10n.analyticsProfitPartial,
      trailing: summary.isProfitComplete
          ? null
          : SdBadgeV3(
              label: context.l10n.commonPartial,
              tone: SdBadgeToneV3.warning,
              icon: AppIconConstant.info,
            ),
      onTap: onTap,
    );
  }
}
