part of 'item_card.dart';

/// The item's photo, or a placeholder well.
///
/// Deliberately larger than the icon tiles elsewhere — in a list of physical
/// objects the picture is what a seller recognises a row by, so it earns the
/// space (`docs/rules/DESIGN_SYSTEM.md`).
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final Item item;

  static double get size => ItemCardMetricConstant.thumbnail;

  @override
  Widget build(BuildContext context) => AppPhoto(
    url: item.photoUrls.isEmpty ? null : item.photoUrls.first,
    size: size,
  );
}
