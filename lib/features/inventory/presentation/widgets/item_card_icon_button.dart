part of 'item_card.dart';

/// An icon-only control on the card's content edge — the actions dots, the
/// arrow into the marketplace prices.
///
/// **A round 44pt target, centred on the glyph** — owner's rule. The actions
/// button was a 36×44 box with the dots pinned to its right edge: a squeezed
/// target, and a ripple that came up as a rounded rectangle nowhere near the
/// thing it was acknowledging. `InkResponse` with a circular highlight is what
/// an icon-only control looks like everywhere else on the platform.
///
/// The whole target stays inside the card's padding. Aligning only the glyph
/// to the content edge made the interactive region overhang the right side
/// and left the card with unequal horizontal padding.
class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;

  /// Also the semantics label: the glyph alone says nothing to a screen
  /// reader, and this is the only text the control has.
  final String tooltip;

  final VoidCallback onPressed;

  /// What the button occupies in a row, so a card that has no button for this
  /// item can hold the same space open and keep its columns aligned.
  static double get slotSize => SdSpacingConstant.r44;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkResponse(
      onTap: onPressed,
      radius: SdSpacingConstant.r22,
      containedInkWell: true,
      highlightShape: BoxShape.circle,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: slotSize,
        height: slotSize,
        child: Center(
          child: SdIconV3(
            icon,
            size: SdIconV3.smallSize,
            color: context.sdTheme3.textTertiary,
            semanticLabel: tooltip,
          ),
        ),
      ),
    ),
  );
}
