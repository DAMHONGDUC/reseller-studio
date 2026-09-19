part of 'home_screen.dart';

/// A compact way into Premium for a Free seller.
///
/// It is not a fourth shortcut: the banner spans the content width and sits
/// immediately above the closed three-card shortcut row. Loading renders
/// nothing so a paid seller never sees an upgrade flash on a cold start.
class _HomePremiumBanner extends ConsumerWidget {
  const _HomePremiumBanner();

  /// Whether this draws anything, so the row beneath it knows whether it
  /// needs a gap. One predicate, read here and at the call site.
  ///
  /// **It asks `currentPlanProvider`, never the purchase record.** A seller
  /// `app_config` grants Premium to has bought nothing, so reading
  /// `subscriptionStatus` offered them an upgrade they already have.
  static bool shows(WidgetRef ref) {
    if (ref.watch(currentPlanProvider) == SellerPlan.premium) return false;

    // The plan answers Free until the entitlement lands, so a paying seller
    // would see an upgrade flash on every cold start without this.
    return ref.watch(subscriptionStatusProvider).hasValue;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!shows(ref)) return const SizedBox.shrink();

    return Padding(
      // Gutter only: the gap under it belongs to the shortcut row below, which
      // Home places with [shows] (`docs/rules/DESIGN_SYSTEM.md`).
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: SdCardV3(
        padding: SdContentPaddingV3.row,
        onTap: () => context.push(AppRoutes.paywall),
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
            const AppRowChevron(),
          ],
        ),
      ),
    );
  }
}
