part of 'item_card.dart';

/// One cell in the money band — its label, and its content under it.
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
    required this.content,
    this.onTap,
    this.tooltip,
  });

  final String label;
  final Widget content;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget cell = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: context.textTheme3.bodySmall!.faint3(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SdSpacingConstant.h2),
        content,
      ],
    );

    final VoidCallback? handleTap = onTap;
    if (handleTap == null) return cell;

    return Tooltip(
      message: tooltip!,
      child: InkResponse(
        onTap: handleTap,
        radius: SdSpacingConstant.r22,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: _CardIconButton.slotSize,
          child: Align(alignment: Alignment.centerLeft, child: cell),
        ),
      ),
    );
  }
}
