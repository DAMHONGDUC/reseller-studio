part of 'home_screen.dart';

class _AllClear extends StatelessWidget {
  const _AllClear();

  @override
  Widget build(BuildContext context) => SdCardV3(
    child: Row(
      children: <Widget>[
        SdIconTileV3(
          icon: Symbols.check_circle_rounded,
          tint: context.sdTheme3.success,
        ),
        SizedBox(width: SdSpacingConstant.w12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'All clear',
                style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                  color: context.sdTheme3.textPrimary,
                ),
              ),
              Text(
                'Nothing needs your attention right now.',
                style: context.textTheme3.bodySmall!.muted3(context),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
