part of 'home_screen.dart';

class _AllClear extends StatelessWidget {
  const _AllClear();

  @override
  Widget build(BuildContext context) => SdCardV3(
    child: Row(
      children: <Widget>[
        SdIconTileV3(
          icon: AppIconConstant.checkCircle,
          tint: context.sdTheme3.success,
        ),
        SizedBox(width: SdSpacingConstant.w12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.homeAllClear,
                style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
              Text(
                context.l10n.homeNothingNeedsYourAttentionRightNow,
                style: context.textTheme3.bodySmall!.muted3(context),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
