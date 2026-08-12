import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../expenses/domain/entities/expense.dart';
import '../../../../expenses/providers.dart';
import '../../../domain/entities/analytics_summary.dart';
import '../../../providers.dart';
import '../../widgets/metric_card.dart';

/// Profit (plan §9) — the statement, in full.
///
/// ```text
/// Revenue
/// - COGS
/// - Platform fees
/// - Shipping
/// - Other expenses
/// ----------------
/// Net Profit
/// ```
///
/// **Nothing here is stored** (hard rule 3). Correcting a fee on one order
/// corrects every line at once, and a report run next year over the same data
/// produces the same number.
///
/// When any sold item has no recorded cost the bottom line is `—`, not a
/// number built on the ones that do. Treating a missing cost as zero would
/// report the whole sale price as profit — the single most misleading thing
/// this app could say.
class AnalyticsProfitScreen extends ConsumerWidget {
  const AnalyticsProfitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsSummary summary = ref.watch(analyticsSummaryProvider);
    final List<Expense> expenses =
        ref.watch(expensesProvider).value ?? const <Expense>[];

    // Only expenses not already attributed to an order — a shipping label
    // charged to an order is inside that order's shipping cost, and counting
    // it twice understates profit.
    final Money? overheads = expenses
        .where((Expense expense) => expense.orderId == null)
        .map((Expense expense) => expense.amount)
        .totalOrNull();

    final Money? profit = summary.netProfit;

    return SdScaffoldV3(
      appBar: const SdAppBarV3(title: 'Profit'),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          MetricCard(
            title: 'The statement',
            rows: <Widget>[
              MetricRow(
                label: 'Revenue',
                value: context.money(summary.revenue),
              ),
              MetricRow(
                label: 'Cost of goods sold',
                value: context.money(summary.costOfGoodsSold),
              ),
              MetricRow(
                label: 'Other expenses',
                value: context.money(overheads),
                caption: 'Overheads not charged to an order',
              ),
              Divider(
                height: SdSpacingConstant.h16,
                thickness: 1,
                color: context.sdTheme3.divider,
              ),
              MetricRow(
                label: 'Net profit',
                value: context.money(profit),
                isEmphasis: true,
                // An em dash is not a figure, so it is never tinted as good
                // or bad news.
                valueColor: profit == null
                    ? null
                    : profit.isNegative
                    ? context.sdTheme3.loss
                    : context.sdTheme3.profit,
              ),
              MetricRow(
                label: 'Margin',
                value: context.percent(summary.margin, decimals: 1),
                caption: 'How much of each unit taken you kept',
              ),
            ],
          ),
          if (!summary.isProfitComplete) ...<Widget>[
            SizedBox(height: SdSpacingConstant.h16),
            SdCardV3(
              child: Text(
                'Some sold items have no recorded cost, so profit cannot be '
                'worked out for them. Add the cost on those items and this '
                'fills in — it is never guessed.',
                style: context.textTheme3.bodySmall!.copyWith(
                  color: context.sdTheme3.warning,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
