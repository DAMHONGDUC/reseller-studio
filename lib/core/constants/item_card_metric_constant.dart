import 'package:system_design/index.dart';

/// The gaps and the glyph size the inventory row is tuned by.
///
/// **One class so the card's density is set in one place** — owner's rule
/// (`lib/features/inventory/CLAUDE.md`). The numbers were spread across six
/// `part` files, so changing the row meant finding every `SizedBox` in it and
/// hoping none had been missed. It is also why opening the gaps back up is a
/// handful of values here rather than a pass over the part files.
///
/// Nothing here removes a fact. Every figure the row carries has a rule of its
/// own and stays; what these set is the air between them.
final class ItemCardMetricConstant {
  /// The photo beside the title.
  ///
  /// Still larger than every `SdIconTileV3` — a list of physical objects is
  /// recognised by its pictures (`docs/rules/DESIGN_SYSTEM.md`) — but no
  /// longer taller than the two lines of text next to it, which is what made
  /// the top of the card measure by the photo rather than by its content.
  static double get thumbnail => SdSpacingConstant.r48;

  /// Title to the tags under it.
  ///
  /// The title is the row's heading and the tags are what qualifies it, so
  /// this gap has to read as a break between two things rather than as one
  /// wrapped line.
  static double get titleGap => SdSpacingConstant.h6;

  /// Between two badges on the tag line.
  static double get tagGap => SdSpacingConstant.w8;

  /// Between two runs of the tag line, when the words are long enough that it
  /// wraps. The tightest gap on the card on purpose: a wrapped run is still
  /// the same line of tags, so it must not open a gap that reads as a break
  /// between two of them.
  static double get tagRunGap => SdSpacingConstant.h4;

  /// Around the hairline over the money band.
  static double get bandGap => SdSpacingConstant.h8;

  /// Between the money band and a consistency warning under it. The same gap
  /// the band itself takes, because the warning is a second line of the band
  /// rather than a third zone.
  static double get warningGap => SdSpacingConstant.h8;

  /// Above the "last updated" line, the quietest thing on the card.
  static double get updatedGap => SdSpacingConstant.h6;
}
