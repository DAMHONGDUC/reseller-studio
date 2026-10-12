part of 'analytics_screen.dart';

/// All · 7D · 30D · 90D · YTD · Custom, on the shared filter strip.
///
/// The same strip every list screen uses (`docs/rules/DESIGN_SYSTEM.md`), and
/// pinned above the scroll for the same reason: a period a seller cannot
/// reach from the bottom of the page is one they scroll back up for.
///
/// **Custom asks for the days, then reads them back.** Its chip shows the
/// range once one is picked, so the strip says what the figures below cover.
class _PeriodStrip extends ConsumerWidget {
  const _PeriodStrip();

  Future<void> _pickCustom(
    BuildContext context,
    WidgetRef ref,
    AnalyticsDateRange? current,
  ) async {
    final DateTime today = DateTimeUtils.startOfDay(
      ref.read(clockProvider).now(),
    );
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - DatePickerConstant.taxRecordYearsBack),
      lastDate: today,
      initialDateRange: current == null
          ? null
          : DateTimeRange(start: current.from, end: current.to),
    );

    if (picked == null) return;
    ref
        .read(analyticsCustomRangeProvider.notifier)
        .pick(AnalyticsDateRange(from: picked.start, to: picked.end));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalyticsPeriod selected = ref.watch(analyticsPeriodProvider);
    final AnalyticsDateRange? custom = ref.watch(analyticsCustomRangeProvider);
    final String locale = context.localeTag;

    return Semantics(
      label: context.l10n.analyticsPeriodLabel,
      container: true,
      child: AppFilterStrip(
        children: <Widget>[
          for (final AnalyticsPeriod period in AnalyticsPeriod.values)
            SdFilterChipV3(
              label: period == AnalyticsPeriod.custom && custom != null
                  ? context.l10n.analyticsPeriodRange(
                      DateTimeUtils.shortDate(custom.from, locale: locale),
                      DateTimeUtils.shortDate(custom.to, locale: locale),
                    )
                  : period.label(context),
              selected: period == selected,
              onSelected: () => period == AnalyticsPeriod.custom
                  ? _pickCustom(context, ref, custom)
                  : ref.read(analyticsPeriodProvider.notifier).select(period),
            ),
        ],
      ),
    );
  }
}
