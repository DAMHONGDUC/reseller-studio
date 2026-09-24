part of 'home_screen.dart';

/// What a guest is owed before they lose anything.
///
/// **The architecture is allowed to make this trade only if the product says
/// so out loud** (`docs/rules/GUEST_MODE.md`). A seller who has not signed in
/// holds the only copy of their business: deleting the app deletes it, and
/// nothing warns them at the moment they would need warning. This is that
/// warning, and it is why it is not dismissible.
///
/// **Above the premium banner**, which is the one place in this app an upsell
/// is deliberately outranked: one of them offers a seller more, the other
/// tells them what they are about to lose.
///
/// It says nothing until there is something to lose — a seller who has not
/// started has nothing to warn about, and the marketplaces and categories a
/// new business is seeded with are not theirs.
class _HomeGuestBanner extends ConsumerWidget {
  const _HomeGuestBanner();

  /// Whether this draws anything, so the widget beneath it knows whether it
  /// needs a gap. One predicate, read here and at the call site.
  static bool shows(WidgetRef ref) {
    if (ref.watch(accountKindProvider) == AccountKind.linked) return false;

    // The seller's own rows, never the reference data a new business is
    // created with — see `guestSellerRowsProvider`.
    return (ref.watch<AsyncValue<int>>(guestSellerRowsProvider).value ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!shows(ref)) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV3.horizontal),
      child: AppStatusCard(
        icon: AppIconConstant.warning,
        // Warning, not primary: this is a risk the seller is carrying, not
        // an offer. Colour is never the only signal — the icon says it too.
        tint: context.sdTheme3.warning,
        borderColor: context.sdTheme3.warning,
        title: context.l10n.homeGuestBannerTitle,
        detail: context.l10n.homeGuestBannerSubtitle,
        semanticLabel: context.l10n.homeGuestBannerTitle,
        onTap: () => context.push(AppRoutes.login),
      ),
    );
  }
}
