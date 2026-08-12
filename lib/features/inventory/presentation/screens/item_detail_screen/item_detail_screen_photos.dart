part of 'item_detail_screen.dart';

/// The item's photos, side by side.
///
/// Nothing at all when there are none: an empty carousel of placeholders on a
/// detail screen is a row of holes, where on a *list* the placeholder earns
/// its place by keeping the row heights equal.
class _Photos extends StatelessWidget {
  const _Photos({required this.urls});

  final List<String> urls;

  static double get size => SdSpacingConstant.r64 * 2;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (BuildContext context, int index) =>
            SizedBox(width: SdSpacingConstant.w8),
        itemBuilder: (BuildContext context, int index) =>
            AppPhoto(url: urls[index], size: size),
      ),
    );
  }
}
