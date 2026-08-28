part of 'item_card.dart';

/// One labelled figure on the money line — `Cost` at the left, `$45.00` at the
/// right.
///
/// **Label and figure are pushed apart, not set side by side** — owner's rule.
/// `Cost`, `Asking` and `Profit` are three different lengths, so a label
/// followed by its figure started each amount at a different place and the
/// three read as a ragged staircase. Pinned to the card's right edge they
/// form a column, which is the only way three amounts can be compared at a
/// glance.
///
/// **The figure is a size louder than its label** — owner's rule. The amounts
/// are what the row exists to show, and a label at the same weight makes the
/// seller hunt for the number among the words introducing it.
class _MoneyCell extends StatelessWidget {
  const _MoneyCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      // Both flexible: the label is the shorter of the two and gives way
      // first, but neither may push the row past the card.
      Flexible(
        child: Text(
          label,
          style: context.textTheme3.bodySmall!.faint3(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      SizedBox(width: SdSpacingConstant.w12),
      Flexible(
        child: Text(
          value,
          style: context.textTheme3.bodyMedium!.bold3.tabular3.copyWith(
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
        ),
      ),
    ],
  );
}
