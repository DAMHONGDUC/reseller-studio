part of 'more_screen.dart';

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.destination, required this.isLast});

  final MoreDestination destination;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color foreground = destination.isBuilt
        ? context.sdTheme3.textPrimary
        : context.sdTheme3.textTertiary;

    return Column(
      children: <Widget>[
        InkWell(
          onTap: destination.isBuilt
              ? () => context.push(destination.route)
              : null,
          child: Padding(
            padding: SdContentPaddingV3.row,
            child: Row(
              children: <Widget>[
                SdIconV3(destination.icon, color: foreground),
                SizedBox(width: SdSpacingConstant.w12),
                Expanded(
                  child: Text(
                    destination.label,
                    style: context.textTheme3.bodyLarge!.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                if (!destination.isBuilt)
                  const SdBadgeV3(label: 'Soon')
                else
                  SdIconV3(
                    Symbols.chevron_right_rounded,
                    size: SdIconV3.smallSize,
                    color: context.sdTheme3.textTertiary,
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: context.sdTheme3.divider),
      ],
    );
  }
}
