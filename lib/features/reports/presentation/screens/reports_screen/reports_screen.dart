import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/time/app_clock.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_stat_tile_row.dart';
import '../../../../analytics/domain/entities/analytics_summary.dart';
import '../../../../analytics/providers.dart';
import '../../../../subscription/domain/enums/plan_feature.dart';
import '../../../../subscription/domain/services/plan_gate.dart';
import '../../../../subscription/presentation/widgets/plan_block_sheet.dart';
import '../../../../subscription/providers.dart';
import '../../../../tax/providers.dart';
import '../../controllers/report_controller.dart';

/// Reports — the numbers, and a way to get them out (plan §19).
///
/// **Export is the feature.** A reseller's year-end goes to an accountant or
/// into a spreadsheet, and the app's job is to hand over rows they can sum
/// rather than to become the accounting software.
///
/// The summary above the exports is this month against the whole record, so
/// the seller can see whether the file they are about to send looks right
/// before they send it.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    ReportKind kind,
  ) async {
    // The seller's own rows stay free — sales, stock, costs. The year's
    // summary is the tax pack's, and is sold with it.
    if (kind == ReportKind.tax &&
        !ref.read(hasFeatureProvider(PlanFeature.taxExport))) {
      await PlanBlockSheet.show(
        context,
        block: PlanBlock.featureLocked,
        plan: ref.read(currentPlanProvider),
      );

      return;
    }

    try {
      await ref.read(reportControllerProvider.notifier).export(kind);
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsSummary summary = ref.watch(analyticsSummaryProvider);
    final bool isBusy = ref.watch(reportControllerProvider);
    final DateTime now = ref.watch(clockProvider).now();

    return SdScaffoldV3(
      appBar: SdAppBarV3(title: context.l10n.moreReports),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          SdSectionHeaderV3(
            title: context.l10n.reportsEverythingToDate,
            subtitle: context.l10n.reportsAsOf(
              DateTimeUtils.mediumDate(now, locale: context.localeTag),
            ),
            first: true,
          ),
          AppStatTileRow(
            left: SdStatTileV3(
              label: context.l10n.commonRevenue,
              value: context.money(summary.revenue, compact: true),
              icon: AppIconConstant.trendingUp,
            ),
            right: SdStatTileV3(
              label: context.l10n.commonNetProfit,
              value: context.money(summary.netProfit, compact: true),
              tone: _profitTone(summary.netProfit),
              caption: summary.isProfitComplete ? null : 'Some costs missing',
              icon: AppIconConstant.savings,
            ),
          ),
          SizedBox(height: SdSpacingConstant.h8),
          AppStatTileRow(
            left: SdStatTileV3(
              label: context.l10n.commonOrders,
              value: '${summary.orderCount}',
              icon: AppIconConstant.receiptLong,
            ),
            right: SdStatTileV3(
              label: context.l10n.analyticsInventoryValue,
              value: context.money(summary.inventoryValue, compact: true),
              icon: AppIconConstant.inventory,
            ),
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          SdSectionHeaderV3(
            title: context.l10n.reportsExport,
            subtitle: context.l10n.reportsCsvReadyForASpreadsheetOr,
            first: true,
          ),
          AppListCard(
            children: <Widget>[
              AppListRow(
                title: context.l10n.analyticsSales,
                subtitle: context.l10n.reportsOneRowPerItemSoldWith,
                icon: AppIconConstant.pointOfSale,
                onTap: isBusy
                    ? null
                    : () => _export(context, ref, ReportKind.sales),
              ),
              AppListRow(
                title: context.l10n.workflowInventory,
                subtitle: context.l10n.reportsEverythingYouHoldWithCostAnd,
                icon: AppIconConstant.inventory,
                onTap: isBusy
                    ? null
                    : () => _export(context, ref, ReportKind.inventory),
              ),
              AppListRow(
                title: context.l10n.commonExpenses,
                subtitle: context.l10n.reportsEveryCostByCategoryAndDate,
                icon: AppIconConstant.receipt,
                onTap: isBusy
                    ? null
                    : () => _export(context, ref, ReportKind.expenses),
              ),
              // The one export scoped to a period: a return is filed for one
              // year, so it follows the year picked on the Tax screen rather
              // than exporting everything.
              //
              // **And the one behind the same gate as the tax pack.** It is
              // the pack's own summary, so leaving it open here sold Premium
              // a capability a Free seller could take one screen over.
              AppListRow(
                title: context.l10n.reportsTaxSummary,
                subtitle: context.l10n.reportsTaxSummaryNote(
                  ref.watch(selectedTaxYearProvider).label,
                ),
                icon: AppIconConstant.receiptLong,
                trailing: ref.watch(hasFeatureProvider(PlanFeature.taxExport))
                    ? null
                    : const SdIconV3(AppIconConstant.lock),
                onTap: isBusy
                    ? null
                    : () => _export(context, ref, ReportKind.tax),
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            context.l10n.reportsAmountsExportAsPlainNumbersSo,
            style: context.textTheme3.bodySmall!.faint3(context),
          ),
        ],
      ),
    );
  }

  /// An em dash is not a figure, so it is never tinted as good or bad news.
  static SdStatToneV3 _profitTone(Money? profit) {
    if (profit == null) return SdStatToneV3.neutral;

    return profit.isNegative ? SdStatToneV3.loss : SdStatToneV3.profit;
  }
}
