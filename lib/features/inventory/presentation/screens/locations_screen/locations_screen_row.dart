part of 'locations_screen.dart';

/// One location, indented to show what it sits inside.
class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.location,
    required this.itemCount,
    required this.onDelete,
  });

  final StorageLocation location;
  final int itemCount;
  final ValueChanged<int> onDelete;

  /// How far each level is inset. One step per level rather than a scaled
  /// tree: three levels is the whole depth, and anything deeper is a data bug
  /// rather than a layout to design for.
  static double indentFor(LocationKind kind) => switch (kind) {
    LocationKind.warehouse => 0,
    LocationKind.shelf => SdSpacingConstant.w16,
    LocationKind.bin => SdSpacingConstant.w32,
  };

  static IconData iconFor(LocationKind kind) => switch (kind) {
    LocationKind.warehouse => AppIconConstant.warehouse,
    LocationKind.shelf => AppIconConstant.shelves,
    LocationKind.bin => AppIconConstant.inbox,
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indentFor(location.kind)),
    child: AppListRow(
      title: location.name,
      subtitle: <String>[
        LocationKindLabel.of(context, location.kind),
        if (itemCount > 0) context.l10n.locationItemCount(itemCount),
        if (location.barcode != null) location.barcode!,
      ].join(' · '),
      icon: iconFor(location.kind),
      showChevron: false,
      trailing: AppRowIconButton(
        icon: AppIconConstant.delete,
        tooltip: context.l10n.actionDelete,
        onPressed: () => onDelete(itemCount),
      ),
    ),
  );
}
