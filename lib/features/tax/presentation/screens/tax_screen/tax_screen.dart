import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../domain/entities/tax_summary.dart';
import '../../../domain/entities/tax_year.dart';
import '../../../domain/enums/tax_jurisdiction.dart';
import '../../../providers.dart';

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
        title: 'Tax',
        subtitle: _authority(jurisdiction),
      ),
      body: ListView(
        padding: SdContentPaddingV3.screen(context),
        children: <Widget>[
          SizedBox(height: SdContentPaddingV3.topGap),
          const _YearStrip(),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          SdSectionHeaderV3(
            title: 'Year ${summary.year.label}',
            subtitle: _period(context, summary.year),
            first: true,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: SdStatTileV3(
                  label: 'Sales',
                  value: context.money(summary.revenue, compact: true),
                  icon: Symbols.point_of_sale_rounded,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: SdStatTileV3(
                  label: 'Cost of goods',
                  value: context.money(summary.costOfGoods, compact: true),
                  icon: Symbols.inventory_2_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: SdSpacingConstant.h8),
          Row(
            children: <Widget>[
              Expanded(
                child: SdStatTileV3(
                  label: 'Deductions',
                  value: context.money(summary.totalDeductions, compact: true),
                  icon: Symbols.receipt_rounded,
                ),
              ),
              SizedBox(width: SdSpacingConstant.w8),
              Expanded(
                child: SdStatTileV3(
                  label: 'Net before tax',
                  value: context.money(summary.netBeforeTax, compact: true),
                  icon: Symbols.savings_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          _Lines(summary: summary),
          SizedBox(height: SdContentPaddingV3.sectionGap),
          _MileageCard(summary: summary, jurisdiction: jurisdiction),
          SizedBox(height: SdSpacingConstant.h16),
          Text(
            'These are your own records grouped into the lines your return '
            'asks for. Nothing here applies allowances, thresholds or rates, '
            'and it is not tax advice — check it with whoever files for you.',
            style: context.textTheme3.bodySmall!.copyWith(
              color: context.sdTheme3.textSecondary,
            ),
          ),
          SizedBox(height: SdContentPaddingV3.bottomGap),
        ],
      ),
    );
  }

  static String _authority(TaxJurisdiction jurisdiction) =>
      switch (jurisdiction) {
        TaxJurisdiction.us => 'Schedule C lines, calendar year',
        TaxJurisdiction.uk => 'SA103 lines, 6 April to 5 April',
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
