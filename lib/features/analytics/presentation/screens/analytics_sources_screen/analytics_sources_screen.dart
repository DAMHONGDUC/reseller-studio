import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../sourcing/providers.dart';
import '../../widgets/metric_card.dart';

/// Source analytics (plan §9) — the last step of the product's lifecycle.
///
/// **This is the screen the whole `Source → Purchase → Item` chain exists
/// for.** Every other analytics screen says what happened; this one says where
/// to go next Saturday. Without it the app can tell a seller what sold and not
/// where to find more of it.
///
/// Sorted by ROI rather than by revenue: the shop that returns 180% on £40 is
/// a better place to spend a morning than the one returning 20% on £400.
class AnalyticsSourcesScreen extends ConsumerWidget {
  const AnalyticsSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String> names = ref.watch(sourceNamesProvider);

    final List<SourcePerformance> rows =
        List<SourcePerformance>.of(ref.watch(sourcePerformanceProvider))
          ..sort((SourcePerformance a, SourcePerformance b) {
            final double? left = a.roi;
            final double? right = b.roi;

            // Sources with no answer sort last: they are not bad, they are
            // unknown, and putting them at the top would bury the ones that
            // have actually been measured.
            if (left == null && right == null) return 0;
            if (left == null) return 1;
            if (right == null) return -1;

            return right.compareTo(left);
          });

    return SdScaffoldV3(
      appBar: const SdAppBarV3(title: 'By source'),
      body: rows.isEmpty
          ? const SdEmptyStateV3(
              icon: Symbols.storefront_rounded,
              title: 'No sources yet',
              message:
                  'Record where stock comes from and this ranks the places '
                  'worth going back to.',
            )
          : ListView(
              padding: SdContentPaddingV3.screen(context),
              children: <Widget>[
                SizedBox(height: SdContentPaddingV3.topGap),
                for (final SourcePerformance row in rows) ...<Widget>[
                  MetricCard(
                    title: names[row.sourceId] ?? row.sourceId,
                    rows: <Widget>[
                      MetricRow(
                        label: 'ROI',
                        value: context.percent(row.roi),
                        isEmphasis: true,
                        valueColor: row.roi == null
                            ? null
                            : row.roi! < 0
                            ? context.sdTheme3.loss
                            : context.sdTheme3.profit,
                      ),
                      MetricRow(
                        label: 'Spent',
                        value: context.money(row.spend),
                      ),
                      MetricRow(
                        label: 'Revenue',
                        value: context.money(row.revenue),
                      ),
                      MetricRow(
                        label: 'Profit',
                        value: context.money(row.profit),
                      ),
                      MetricRow(
                        label: 'Items',
                        value: '${row.itemsSold} / ${row.itemsBought}',
                        caption: 'Sold of bought',
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
