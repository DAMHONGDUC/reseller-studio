part of 'more_screen.dart';

class _MoreSection extends StatelessWidget {
  const _MoreSection({
    required this.section,
    required this.plan,
    required this.signedIn,
  });

  final MoreSection section;

  /// Passed down rather than watched in the row: one read per screen, and a
  /// row stays a `StatelessWidget`.
  final SellerPlan plan;

  final bool signedIn;

  @override
  Widget build(BuildContext context) => AppSection(
    title: MoreSectionLabel.of(context, section.kind),
    padding: EdgeInsets.zero,
    child: Column(
      children: <Widget>[
        for (int index = 0; index < section.destinations.length; index++)
          _MoreRow(
            destination: section.destinations[index],
            isLast: index == section.destinations.length - 1,
            plan: plan,
            signedIn: signedIn,
          ),
      ],
    ),
  );
}
