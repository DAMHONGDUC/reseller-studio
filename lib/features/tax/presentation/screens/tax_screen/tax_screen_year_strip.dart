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

    return AppFilterStrip(
      children: <Widget>[
        for (final TaxYear year in years)
          SdFilterChipV3(
            label: year.label,
            selected: year == selected,
            onSelected: () =>
                ref.read(selectedTaxYearProvider.notifier).select(year),
          ),
      ],
    );
  }
}
