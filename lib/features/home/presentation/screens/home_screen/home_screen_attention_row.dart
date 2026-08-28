part of 'home_screen.dart';

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.tint,
    this.detail,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color tint;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: SdContentPaddingV3.card,
      child: Row(
        children: <Widget>[
          SdIconTileV3(icon: icon, tint: tint),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: context.textTheme3.bodySmall!.muted3(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          // The count is the point of the row, so it is set at title weight
          // in the tint rather than tucked into a badge.
          Text(
            '$count',
            style: context.textTheme3.titleLarge!.tabular3.copyWith(
              color: tint,
            ),
          ),
          SizedBox(width: SdSpacingConstant.w4),
          SdIconV3(
            AppIconConstant.chevronRight,
            size: SdIconV3.smallSize,
            color: context.sdTheme3.textTertiary,
          ),
        ],
      ),
    ),
  );
}
