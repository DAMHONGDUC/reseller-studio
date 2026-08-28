part of 'home_screen.dart';

/// A full-width explanation entry, directly below the one-glance shortcuts.
class _HomeFlowOverview extends StatelessWidget {
  const _HomeFlowOverview();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
    child: SdCardV3(
      onTap: () => FlowOverviewSheet.show(context),
      semanticLabel: context.l10n.homeFlowOverview,
      child: Row(
        children: <Widget>[
          SdIconTileV3(
            icon: Symbols.account_tree_rounded,
            tint: context.colorScheme3.primary,
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Text(
              context.l10n.flowOverviewIntro,
              style: context.textTheme3.bodyMedium!.copyWith(
                color: context.sdTheme3.textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          SdIconV3(
            Symbols.chevron_right_rounded,
            size: SdIconV3.smallSize,
            color: context.sdTheme3.textTertiary,
          ),
        ],
      ),
    ),
  );
}
