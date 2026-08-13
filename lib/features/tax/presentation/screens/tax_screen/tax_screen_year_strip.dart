part of 'tax_screen.dart';

/// Which year the summary is for.
///
/// A horizontal strip rather than a dropdown: a seller comparing this year
/// with last year taps between them repeatedly, and a picker that has to be
/// opened each time turns one comparison into four taps.
class _YearStrip extends ConsumerWidget {
  const _YearStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TaxYear> years = ref.watch(selectableTaxYearsProvider);
    final TaxYear selected = ref.watch(selectedTaxYearProvider);

    return SizedBox(
      height: SdContentPaddingV3.filterStrip,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          vertical: SdContentPaddingV3.filterStripGap,
        ),
        itemCount: years.length,
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(width: SdSpacingConstant.w8),
        itemBuilder: (BuildContext context, int index) => SdFilterChipV3(
          label: years[index].label,
          selected: years[index] == selected,
          onSelected: () => ref
              .read(selectedTaxYearProvider.notifier)
              .select(years[index]),
        ),
      ),
    );
  }
}
