import 'package:system_design/index.dart';

/// The gaps and the glyph the inventory row tightens.
///
/// **One class so the card can be made denser in one place** — owner's rule
/// (`lib/features/inventory/CLAUDE.md`). The numbers were spread across six
/// `part` files, so shrinking the row meant finding every `SizedBox` in it and
/// hoping none had been missed.
///
/// Nothing here removes a fact. Every figure the row carries has a rule of its
/// own and stays; what these close is the air between them.
final class ItemCardMetricConstant {
  /// The photo beside the title.
  ///
  /// Still larger than every `SdIconTileV3` — a list of physical objects is
  /// recognised by its pictures (`docs/rules/DESIGN_SYSTEM.md`) — but no
  /// longer taller than the two lines of text next to it, which is what made
  /// the top of the card measure by the photo rather than by its content.
  static double get thumbnail => SdSpacingConstant.r48;

  /// Title to the tags under it.
  static double get titleGap => SdSpacingConstant.h4;

  /// Between the two tag lines: what the item is, and where it is listed.
  static double get tagLineGap => SdSpacingConstant.h2;

  /// Around the hairline over the money band.
  static double get bandGap => SdSpacingConstant.h8;

  /// Above the "last updated" line, the quietest thing on the card.
  static double get updatedGap => SdSpacingConstant.h4;
}
