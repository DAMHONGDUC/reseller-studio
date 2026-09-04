part of 'item_card.dart';

/// One cell in the money band — its label, and its content under it.
///
/// **Label above, not beside.** Set side by side, `Cost`, `Asking` and
/// `Profit` are three different lengths, so every amount started at a
/// different place; pushed to opposite edges instead, each label ended up
/// stranded a card's width from the number it names. Stacked, the labels
/// share one baseline and the amounts share the next.
///
/// **A cell that opens something aligns to the end** — owner's rule. Its
/// glyph holds the card's right edge, in the same column as the chevron every
/// other card ends with; centred in a square target it sat 12 points short.
///
/// **It lays out at its own height and overhangs for its target** — owner's
/// rule, the same one `AppRowIconButton` follows
/// (`docs/rules/DESIGN_SYSTEM.md`). A 44pt box in the layout made the band
/// taller than the two lines it holds and left the dead space under the
/// arrow, while the two cells beside it stopped at their text; the ink
/// spreads over the card's own inset instead, which nothing else is using.
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
      // A cell that opens something ends the row, so it aligns to the end and
      // its glyph holds the card's right edge — the column every other card's
      // chevron sits in.
      crossAxisAlignment: onTap == null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
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
        // The ink reaches the 44pt target the layout no longer reserves, and
        // only the label's width — a square would centre the pair and pull
        // the glyph off the card's edge.
        radius: AppRowIconButton.target / 2,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        customBorder: const CircleBorder(),
        child: cell,
      ),
    );
  }
}
