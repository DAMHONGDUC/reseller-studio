part of 'home_screen.dart';

/// One thing waiting on the seller: the count large, what it is under it.
///
/// **The count is read first.** As a row it sat at the end of a line of text,
/// the last thing the eye reached; a tile sets it at headline size above the
/// label.
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SdIconTileV3(icon: icon, tint: tint),
        SizedBox(height: SdSpacingConstant.h12),
        Text(
          '$count',
          style: context.textTheme3.headlineMedium!.tabular3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
        ),
        SizedBox(height: SdSpacingConstant.h2),
        Text(
          label,
          style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
            color: context.sdTheme3.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (detail != null) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h2),
          Text(
            detail!,
            style: isUrgent
                ? context.textTheme3.bodySmall!.semiBold3.copyWith(color: tint)
                : context.textTheme3.bodySmall!.muted3(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    ),
  );
}
