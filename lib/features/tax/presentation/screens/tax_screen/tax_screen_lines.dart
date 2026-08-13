part of 'tax_screen.dart';

/// Every line of the form, in the form's own order.
///
/// **Empty lines are shown, not hidden.** This screen is read next to a
/// return, and a seller ticking boxes down the form needs the line to be
/// there even when it came to nothing — a missing row reads as "the app lost
/// it", and hard rule 5 already says the amount renders `—` rather than `0`.
class _Lines extends StatelessWidget {
  const _Lines({required this.summary});

  final TaxSummary summary;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SdSectionHeaderV3(
        title: 'Expenses by line',
        subtitle: 'Your categories, grouped the way the form asks',
        first: true,
      ),
      AppListCard(
        children: <Widget>[
          for (final TaxLineTotal line in summary.lines)
            AppListRow(
              title: line.line,
              trailingText: context.money(line.amount),
              showChevron: false,
            ),
        ],
      ),
    ],
  );
}

/// Mileage, kept apart from the money lines.
///
/// It is deducted at the published rate per mile rather than at what was
/// spent, so showing it inside "expenses by line" would invite the seller to
/// add it to a fuel receipt they also recorded — the double-count this whole
/// feature has to avoid.
class _MileageCard extends StatelessWidget {
  const _MileageCard({required this.summary, required this.jurisdiction});

  final TaxSummary summary;
  final TaxJurisdiction jurisdiction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SdSectionHeaderV3(
        title: 'Mileage',
        subtitle: 'Deducted at the published rate, not at what you spent',
        first: true,
      ),
      AppListCard(
        children: <Widget>[
          AppListRow(
            title: 'Distance',
            subtitle: _unit(jurisdiction),
            icon: Symbols.directions_car_rounded,
            trailingText: summary.mileageDistance <= 0
                ? null
                : summary.mileageDistance.toStringAsFixed(0),
            showChevron: false,
          ),
          AppListRow(
            title: 'Deduction',
            // Null here means no published rate for that year, which is a
            // different problem from "no miles" — say which.
            subtitle: summary.mileageDistance > 0 &&
                    summary.mileageDeduction == null
                ? 'No published rate for this year yet'
                : null,
            icon: Symbols.calculate_rounded,
            trailingText: context.money(summary.mileageDeduction),
            showChevron: false,
          ),
        ],
      ),
    ],
  );

  static String _unit(TaxJurisdiction jurisdiction) =>
      switch (jurisdiction.mileageUnit) {
        MileageUnit.mile => 'Miles recorded this year',
        MileageUnit.kilometre => 'Kilometres recorded this year',
      };
}
