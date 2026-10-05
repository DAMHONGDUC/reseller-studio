part of 'home_screen.dart';

/// One thing waiting on the seller: its icon and count on one line, what it
/// is under them.
///
/// **The count is read first.** As a row it sat at the end of a line of text,
/// the last thing the eye reached; a tile sets it at headline size, top left.
///
/// **Compact** — owner's rule (`lib/features/home/CLAUDE.md`). The count sits
/// beside its icon rather than under it, so the block is a glance above the
/// fold instead of half the screen.
///
/// [isUrgent] adds a tinted edge for a problem with a clock on it. The detail
/// line says the same thing in words — colour is never the only signal.
class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.tint,
    this.detail,
    this.isUrgent = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color tint;
  final String? detail;
  final bool isUrgent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SdCardV3(
    onTap: onTap,
    borderColor: isUrgent ? tint : null,
    semanticLabel: '$label: $count',
    padding: EdgeInsets.all(SdSpacingConstant.w12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SdIconTileV3(icon: icon, tint: tint, size: SdIconTileSizeV3.small),
            SizedBox(width: SdSpacingConstant.w8),
            Flexible(
              child: Text(
                '$count',
                style: context.textTheme3.headlineSmall!.tabular3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h6),
        Text(
          label,
          style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (detail != null)
          Text(
            detail!,
            style: isUrgent
                ? context.textTheme3.bodySmall!.semiBold3.copyWith(color: tint)
                : context.textTheme3.bodySmall!.muted3(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    ),
  );
}
