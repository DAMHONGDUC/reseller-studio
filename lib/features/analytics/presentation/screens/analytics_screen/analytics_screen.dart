import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/analytics_summary.dart';
import '../../../providers.dart';

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
      appBar: const SdAppBarV3(title: 'Analytics'),
      body: ListView(
        padding: SdContentPaddingV3.fullBleed(context, floatingNav: true),
        children: <Widget>[
          const SdSectionHeaderV3(title: 'Overview', first: true),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SdContentPaddingV3.horizontal,
            ),
            child: _ProfitStatement(summary: summary),
          ),
          const SdSectionHeaderV3(
            title: 'By marketplace',
            subtitle: 'Where the money actually comes from',
          ),
          const _MarketplaceBreakdown(),
        ],
      ),
    );
  }
}

/// The plan's profit statement (§9), rendered as the subtraction it is.
///
/// Shown as a running deduction rather than four separate tiles because that
/// is how a seller checks it: revenue at the top, each cost taken off, net at
/// the bottom. Four tiles would show the same numbers and hide the arithmetic.
class _ProfitStatement extends StatelessWidget {
  const _ProfitStatement({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) => SdCardV3(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _StatementRow(
          label: 'Revenue',
          value: context.money(summary.revenue),
          isTotal: true,
        ),
        _StatementRow(
          label: 'Cost of goods',
          value: context.money(summary.costOfGoodsSold),
          isDeduction: true,
        ),
        _StatementRow(
          label: 'Expenses',
          value: context.money(summary.totalExpenses),
          isDeduction: true,
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h8),
          child: Divider(
            height: 1,
            thickness: 1,
            color: context.sdTheme3.divider,
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Net profit',
                style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
            ),
            Text(
              context.money(summary.netProfit),
              style: context.textTheme3.titleMedium!.bold3.tabular3.copyWith(
                color: summary.netProfit == null
                    ? context.sdTheme3.textTertiary
                    : summary.netProfit!.isNegative
                    ? context.sdTheme3.loss
                    : context.sdTheme3.profit,
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h8),
        // Wrap, not Row: three badges whose labels grow with the numbers in
        // them overflowed the card by 44px on a narrow screen. A Row cannot
        // give way; this drops to a second line instead.
        Wrap(
          spacing: SdSpacingConstant.w6,
          runSpacing: SdSpacingConstant.h4,
          children: <Widget>[
            SdBadgeV3(label: 'Margin ${context.percent(summary.margin)}'),
            SdBadgeV3(label: '${summary.orderCount} orders'),
            // Saying the figure is partial is the difference between a number
            // a seller can act on and one that quietly misleads.
            if (!summary.isProfitComplete)
              const SdBadgeV3(
                label: 'Partial',
                tone: SdBadgeToneV3.warning,
                icon: Symbols.info_rounded,
              ),
          ],
        ),
      ],
    ),
  );
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({
    required this.label,
    required this.value,
    this.isDeduction = false,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isDeduction;
  final bool isTotal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h4),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            isDeduction ? '− $label' : label,
            style: isTotal
                ? context.textTheme3.bodyMedium!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  )
                : context.textTheme3.bodyMedium!.muted3(context),
          ),
        ),
        Text(
          value,
          style: context.textTheme3.bodyMedium!.tabular3.copyWith(
            color: isTotal
                ? context.sdTheme3.textPrimary
                : context.sdTheme3.textSecondary,
            fontWeight: isTotal ? FontWeight.w600 : null,
          ),
        ),
      ],
    ),
  );
}

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
      return const SdEmptyStateV3(
        icon: Symbols.bar_chart_rounded,
        title: 'No sales yet',
        message: 'Marketplace performance appears once you have orders.',
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
                  color: AppColors.chartSeries[i % AppColors.chartSeries.length],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceRow extends StatelessWidget {
  const _MarketplaceRow({
    required this.row,
    required this.maxRevenue,
    required this.color,
  });

  final MarketplacePerformance row;
  final int maxRevenue;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              row.marketplace.displayName,
              style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
            ),
          ),
          Text(
            context.money(row.revenue),
            style: context.textTheme3.bodyMedium!.tabular3.copyWith(
              color: context.sdTheme3.textPrimary,
            ),
          ),
        ],
      ),
      SizedBox(height: SdSpacingConstant.h6),
      ClipRRect(
        borderRadius: SdRadiusV3.fullAll,
        child: LinearProgressIndicator(
          value: maxRevenue == 0 ? 0 : row.revenue.minor / maxRevenue,
          minHeight: SdSpacingConstant.h8,
          backgroundColor: context.sdTheme3.surfaceSunken,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      SizedBox(height: SdSpacingConstant.h6),
      Text(
        '${row.orderCount} orders · fees ${context.money(row.fees)} '
        '(${context.percent(row.feeRate, decimals: 1)}) · '
        'profit ${context.money(row.profit)}',
        style: context.textTheme3.bodySmall!.muted3(context),
      ),
    ],
  );
}
