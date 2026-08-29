part of 'home_screen.dart';

/// A full-width explanation entry, directly below the one-glance shortcuts.
class _HomeFlowOverview extends StatelessWidget {
  const _HomeFlowOverview();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: SdContentPaddingV3.horizontal,
      top: SdContentPaddingV3.sectionGap,
      right: SdContentPaddingV3.horizontal,
    ),
    child: SdCardV3(
      onTap: () => FlowOverviewSheet.show(context),
      child: Row(
        children: <Widget>[
          SdIconTileV3(
            icon: AppIconConstant.accountTree,
            tint: context.colorScheme3.primary,
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.homeFlowOverview,
                  style: context.textTheme3.titleSmall!.semiBold3.copyWith(
                    color: context.sdTheme3.textPrimary,
                  ),
                ),
                SizedBox(height: SdSpacingConstant.h4),
                Text(
                  context.l10n.flowOverviewIntro,
                  style: context.textTheme3.bodySmall!.muted3(context),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          const AppRowChevron(),
        ],
      ),
    ),
  );
}
