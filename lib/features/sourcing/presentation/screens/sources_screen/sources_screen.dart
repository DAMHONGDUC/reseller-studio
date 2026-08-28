import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/error/failure_presenter.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/widgets/app_add_fab_scaffold.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/name_entry_sheet.dart';
import '../../../domain/entities/source.dart';
import '../../../providers.dart';
import '../../controllers/sourcing_controller.dart';

/// Sources, ranked by what they actually returned (plan §9, Source section).
///
/// **The ranking is the point.** A list of shop names is an address book; a
/// list ordered by ROI is the last step of the product's lifecycle — *source
/// better* — and the only reason to record where something came from.
///
/// ROI renders `—` when either the spend or the revenue is unknown (hard rule
/// 5). A source whose purchases have no recorded total has no answer, and
/// guessing one would rank it above shops that do.
class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final String? name = await NameEntrySheet.show(
      context,
      title: context.l10n.sourcingNewSource,
      label: context.l10n.commonName,
      hint: context.l10n.sourcingGoodwillRiverside,
    );

    if (name == null || !context.mounted) return;

    try {
      // No success message on an add: the new row appears in the list behind
      // the sheet, which is the confirmation (owner's rule).
      await ref
          .read(sourcingControllerProvider.notifier)
          .saveSource(name: name);
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
    final AsyncValue<List<Source>> source = ref.watch(sourcesProvider);
    final List<Source> sources = source.value ?? const <Source>[];
    final List<SourcePerformance> performance = ref.watch(
      sourcePerformanceProvider,
    );

    final Map<String, SourcePerformance> byId = <String, SourcePerformance>{
      for (final SourcePerformance row in performance) row.sourceId: row,
    };

    return AppAddFabScaffold(
      appBar: SdAppBarV3(title: context.l10n.analyticsSources),
      addLabel: 'Add a source',
      onAdd: () => _add(context, ref),
      body: switch (source) {
        AsyncLoading<List<Source>>() when !source.hasValue =>
          const SdLoadingV3Page(),
        _ when sources.isEmpty => SdEmptyStateV3(
          icon: Symbols.storefront_rounded,
          title: context.l10n.analyticsNoSourcesYet,
          message: context.l10n.sourcingRecordWhereStockComesFromAnd,
          action: SdButtonV3(
            variant: SdButtonVariantV3.primary,
            label: context.l10n.homeQuickAddSource,
            onPressed: () => _add(context, ref),
          ),
        ),
        _ => ListView(
          padding: AppAddFabScaffold.listPadding(context),
          children: <Widget>[
            SizedBox(height: SdContentPaddingV3.topGap),
            AppListCard(
              children: sources.map((Source item) {
                final SourcePerformance? row = byId[item.id];

                return AppListRow(
                  title: item.name,
                  subtitle: row == null
                      ? null
                      : '${row.itemsBought} bought · ${row.itemsSold} sold · '
                            'spent ${context.money(row.spend, compact: true)}',
                  icon: Symbols.storefront_rounded,
                  showChevron: false,
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        context.percent(row?.roi),
                        style: context.textTheme3.bodyMedium!.semiBold3.tabular3
                            .copyWith(color: _roiColour(context, row?.roi)),
                      ),
                      Text(
                        context.l10n.commonRoi,
                        style: context.textTheme3.bodySmall!.faint3(context),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      },
    );
  }

  /// An em dash is not a figure, so it is never tinted as good or bad news.
  static Color _roiColour(BuildContext context, double? roi) {
    if (roi == null) return context.sdTheme3.textSecondary;

    return roi < 0 ? context.sdTheme3.loss : context.sdTheme3.profit;
  }
}
