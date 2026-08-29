part of 'item_card.dart';

/// One figure in the money band — its label, and the amount under it.
///
/// **Label above, not beside.** Set side by side, `Cost`, `Asking` and
/// `Profit` are three different lengths, so every amount started at a
/// different place; pushed to opposite edges instead, each label ended up
/// stranded a card's width from the number it names. Stacked, the labels
/// share one baseline and the amounts share the next.
///
/// **The amount is a size louder than its label** — owner's rule. The figures
/// are what the row exists to show, and a label at the same weight makes the
/// seller hunt for the number among the words introducing it.
class _MoneyCell extends StatelessWidget {
  const _MoneyCell({
    required this.label,
    required this.value,
    required this.color,
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color color;

  /// Which edge of the cell the label and the figure sit on. The last cell in
  /// a space-between band ends on the card's edge, so it aligns to it.
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignment,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        label,
        style: context.textTheme3.bodySmall!.faint3(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      SizedBox(height: SdSpacingConstant.h2),
      Text(
        value,
        style: context.textTheme3.bodyMedium!.bold3.tabular3.copyWith(
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
