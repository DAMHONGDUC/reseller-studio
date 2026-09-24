part of 'more_screen.dart';

/// A titled card of rows with a hairline between each.
class _MoreRowsSection extends StatelessWidget {
  const _MoreRowsSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => AppSection(
    title: title,
    padding: EdgeInsets.zero,
    child: Column(
      children: <Widget>[
        for (int index = 0; index < rows.length; index++) ...<Widget>[
          rows[index],
          if (index < rows.length - 1) const SdDividerV3(),
        ],
      ],
    ),
  );
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({required this.section, required this.plan});

  final MoreSection section;

  /// Passed down rather than watched in the row: one read per screen, and a
  /// row stays a `StatelessWidget`.
  final SellerPlan plan;

  @override
  Widget build(BuildContext context) => _MoreRowsSection(
    title: MoreSectionLabel.of(context, section.kind),
    rows: <Widget>[
      for (final MoreDestination destination in section.destinations)
        _MoreRow(destination: destination, plan: plan),
    ],
  );
}
