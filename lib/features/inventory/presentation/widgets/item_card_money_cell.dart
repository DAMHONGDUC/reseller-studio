part of 'item_card.dart';

/// One labelled figure on the money line — `Cost $45.00`.
///
/// **Label and value on one line, not stacked.** The stacked version cost the
/// row a whole line of height to say two words, and three of them side by
/// side read as a table nobody wanted inside a list row.
class _MoneyCell extends StatelessWidget {
  const _MoneyCell({
    required this.label,
    required this.value,
    required this.color,
    this.textAlign = TextAlign.start,
  });

  final String label;
  final String value;
  final Color color;
  final TextAlign textAlign;

  @override
  // One paragraph rather than a Row of two Texts: the label and the figure
  // must ellipsize as one thing, and a Row would clip whichever child the
  // constraints reached first.
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: <InlineSpan>[
        TextSpan(text: '$label '),
        TextSpan(
          text: value,
          style: context.textTheme3.bodySmall!.semiBold3.tabular3.copyWith(
            color: color,
          ),
        ),
      ],
    ),
    style: context.textTheme3.bodySmall!.faint3(context),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: textAlign,
  );
}
