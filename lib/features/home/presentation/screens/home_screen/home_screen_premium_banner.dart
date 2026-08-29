part of 'home_screen.dart';

/// A compact way into Premium for a Free seller.
///
/// It is not a fourth shortcut: the banner spans the content width and sits
/// immediately above the closed three-card shortcut row. Loading renders
/// nothing so a paid seller never sees an upgrade flash on a cold start.
class _HomePremiumBanner extends ConsumerWidget {
  const _HomePremiumBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SellerPlan? plan = ref.watch(subscriptionStatusProvider).value?.plan;

    if (plan == null || plan == SellerPlan.premium) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        0,
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.listItemGap,
      ),
      child: SdCardV3(
        padding: SdContentPaddingV3.row,
        onTap: () => context.push(AppRoutes.subscription),
        semanticLabel: context.l10n.homePremiumBannerAction,
        borderColor: context.colorScheme3.primary,
        child: Row(
          children: <Widget>[
            SdIconTileV3(
              icon: AppIconConstant.workspacePremium,
              tint: context.colorScheme3.primary,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    context.l10n.homePremiumBannerTitle,
                    style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                  ),
                  SizedBox(height: SdSpacingConstant.h4),
                  Text(
                    context.l10n.homePremiumBannerSubtitle,
                    style: context.textTheme3.bodySmall!.copyWith(
                      color: context.sdTheme3.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            Icon(
              AppIconConstant.chevronRight,
              color: context.sdTheme3.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
