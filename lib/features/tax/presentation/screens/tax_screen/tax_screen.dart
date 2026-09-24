import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/app_icon_constant.dart';
import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_filter_strip.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_section.dart';
import '../../../../reports/domain/services/bookkeeping_gaps.dart';
import '../../../../reports/presentation/controllers/report_controller.dart';
import '../../../../reports/providers.dart';
import '../../../../subscription/domain/enums/plan_feature.dart';
import '../../../../subscription/domain/services/plan_gate.dart';
import '../../../../subscription/presentation/widgets/plan_block_sheet.dart';
import '../../../../subscription/providers.dart';
import '../../../domain/entities/tax_summary.dart';
import '../../../domain/entities/tax_year.dart';
import '../../../domain/enums/tax_jurisdiction.dart';
import '../../../providers.dart';

part 'tax_screen_export.dart';
part 'tax_screen_lines.dart';
part 'tax_screen_year_strip.dart';

/// Tax — the year-end summary, grouped into the lines a return asks for
/// (plan §20).
///
/// **A summary of the seller's own records, not a tax computation.** It
/// applies no allowances, thresholds or rates, and the screen says so at the
/// bottom rather than in a dialog nobody reads. Anything that looked like
/// "tax owed" would be advice this app is not in a position to give.
///
/// The jurisdiction comes from the workspace's country, so a UK seller's year
/// opens in April and their lines are named after SA103 rather than
/// Schedule C — `CLAUDE.md` makes that a value, never a branch.
class TaxScreen extends ConsumerWidget {
  const TaxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TaxSummary summary = ref.watch(taxSummaryProvider);
    final TaxJurisdiction jurisdiction = ref.watch(taxJurisdictionProvider);

    return SdScaffoldV3(
      appBar: SdAppBarV3(
        title: context.l10n.moreTax,
        subtitle: _authority(context, jurisdiction),
      ),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          const _YearStrip(),
          // The strip's own bottom gap, and the only one — owner's rule. The
          // section header below it does not add `sectionGap` on top: that
          // would be the same boundary paid for twice.
          SizedBox(height: SdContentPaddingV3.topGap),
          SdSectionHeaderV3(
            title: context.l10n.taxYearLabel(summary.year.label),
            subtitle: _period(context, summary.year),
            first: true,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: SdStatTileV3(
                  label: context.l10n.analyticsSales,
                  value: context.money(summary.revenue, compact: true),
                  icon: AppIconConstant.pointOfSale,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: SdStatTileV3(
                  label: context.l10n.commonCostOfGoods,
                  value: context.money(summary.costOfGoods, compact: true),
                  icon: AppIconConstant.inventory,
                ),
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Row(
            children: <Widget>[
              Expanded(
                child: SdStatTileV3(
                  label: context.l10n.taxDeductions,
                  value: context.money(summary.totalDeductions, compact: true),
                  icon: AppIconConstant.receipt,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: SdStatTileV3(
                  label: context.l10n.taxNetBeforeTax,
                  value: context.money(summary.netBeforeTax, compact: true),
                  icon: AppIconConstant.savings,
                ),
              ),
            ],
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          _Lines(summary: summary),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          _MileageCard(summary: summary, jurisdiction: jurisdiction),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          const _ExportPack(),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            context.l10n.taxTheseAreYourOwnRecordsGrouped,
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          SizedBox(height: SdContentPaddingV3.bottomGap),
        ],
      ),
    );
  }

  static String _authority(
    BuildContext context,
    TaxJurisdiction jurisdiction,
  ) => switch (jurisdiction) {
    TaxJurisdiction.us => context.l10n.taxAuthorityUs,
    TaxJurisdiction.uk => context.l10n.taxAuthorityUk,
  };

  /// The period spelled out, because "2026/27" means nothing until you see
  /// the two dates behind it.
  static String _period(BuildContext context, TaxYear year) {
    final String from = DateTimeUtils.mediumDate(
      year.start,
      locale: context.localeTag,
    );

    final String to = DateTimeUtils.mediumDate(
      year.endExclusive.subtract(const Duration(days: 1)),
      locale: context.localeTag,
    );

    return '$from — $to';
  }
}
