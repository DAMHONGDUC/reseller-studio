part of 'item_card.dart';

/// The item's photo, or a placeholder well.
///
/// A placeholder rather than nothing: without it, rows with photos and rows
/// without would have different heights and the list would look broken.
///
/// Deliberately larger than the icon tiles elsewhere — in a list of physical
/// objects the picture is what a seller recognises a row by, so it earns the
/// space even while it is still a placeholder.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final Item item;

  static double get size => SdSpacingConstant.r64;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.sdTheme3.surfaceSunken,
      borderRadius: SdRadiusV3.thumbnailAll,
      border: Border.all(color: context.sdTheme3.divider),
    ),
    alignment: Alignment.center,
    child: SdIconV3(
      Symbols.image_rounded,
      size: SdIconV3.defaultSize,
      color: context.sdTheme3.textTertiary,
    ),
  );
}
