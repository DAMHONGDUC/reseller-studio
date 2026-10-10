part of 'analytics_screen.dart';

/// All · 7D · 30D · 90D · YTD, on the shared filter strip.
///
/// The same strip every list screen uses (`docs/rules/DESIGN_SYSTEM.md`), and
/// pinned above the scroll for the same reason: a period a seller cannot
/// reach from the bottom of the page is one they scroll back up for.
class _PeriodStrip extends ConsumerWidget {
  const _PeriodStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsPeriod selected = ref.watch(analyticsPeriodProvider);

    return Semantics(
      label: context.l10n.analyticsPeriodLabel,
      container: true,
      child: AppFilterStrip(
        children: <Widget>[
          for (final AnalyticsPeriod period in AnalyticsPeriod.values)
            SdFilterChipV3(
              label: period.label(context),
              selected: period == selected,
              onSelected: () =>
                  ref.read(analyticsPeriodProvider.notifier).select(period),
            ),
        ],
      ),
    );
  }
}
