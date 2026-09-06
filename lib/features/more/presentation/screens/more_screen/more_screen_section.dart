part of 'more_screen.dart';

class _MoreSection extends StatelessWidget {
  const _MoreSection({
    required this.section,
    required this.first,
    required this.plan,
    required this.signedIn,
  });

  final MoreSection section;
  final bool first;

  /// Passed down rather than watched in the row: one read per screen, and a
  /// row stays a `StatelessWidget`.
  final SellerPlan plan;

  final bool signedIn;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SdSectionHeaderV3(
        title: MoreSectionLabel.of(context, section.kind),
        first: first,
      ),
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV3.horizontal,
        ),
        child: SdCardV3(
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
        ),
      ),
    ],
  );
}
