part of 'listings_screen.dart';

/// The bar that appears once listings are ticked.
///
/// **Bulk price update is plan §12's own requirement**, and hard rule 16 makes
/// it first-class: a seller clearing stale stock cuts the price on a screenful
/// at once. Pausing and ending are the other two things done to many listings
/// and never to one.
///
/// Sitting in the scaffold's bottom slot rather than floating: this screen is
/// a pushed route with no glass bar under it and no FAB to compete with, so
/// the bar can take real layout space and nothing is covered.
class _ListingBulkBar extends ConsumerWidget implements PreferredSizeWidget {
  const _ListingBulkBar();

  /// Two rows of controls plus the card's own padding. A `PreferredSize` is
  /// what the scaffold's bottom slot takes, and it cannot measure the child.
  @override
  Size get preferredSize => Size.fromHeight(SdSpacingConstant.h108);

  Future<void> _reprice(BuildContext context, WidgetRef ref) {
    final List<Listing> listings = ref.read(selectedListingsProvider);

    return PriceEntrySheet.show(
      context,
      title: context.l10n.listingRepriceTitle(listings.length),
      fieldLabel: context.l10n.repriceNewPrice,
      submitLabel: context.l10n.repriceSubmit,
      initialPrice: _sharedPrice(listings),
      helperText: context.l10n.listingRepriceHelp,
      onSubmit: (Money price) async {
        await ref
            .read(listingActionsControllerProvider.notifier)
            .reprice(listings, price);

        if (!context.mounted) return;

        ref.read(listingSelectionProvider.notifier).clear();
        SdSnackBarUtilsV3.success(
          context,
          context.l10n.listingRepriceDone(listings.length),
        );
      },
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    ListingStatus status,
  ) async {
    final List<Listing> listings = ref.read(selectedListingsProvider);

    try {
      await ref
          .read(listingActionsControllerProvider.notifier)
          .setStatus(listings, status);

      if (!context.mounted) return;

      ref.read(listingSelectionProvider.notifier).clear();
      SdSnackBarUtilsV3.success(
        context,
        context.l10n.listingStatusChanged(
          listings.length,
          ListingStatusLabel.of(context, status),
        ),
      );
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  /// The price to start the reprice field at, or null when the selection
  /// disagrees — a number belonging to one of forty rows, applied to all
  /// forty, is a silent bulk edit nobody asked for.
  static Money? _sharedPrice(List<Listing> listings) {
    if (listings.isEmpty) return null;

    final Money first = listings.first.price;

    return listings.every((Listing listing) => listing.price == first)
        ? first
        : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(listingSelectionProvider).length;
    final bool isBusy = ref.watch(listingActionsControllerProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV3.horizontal,
        ),
        child: SdCardV3(
          layer: SdCardLayerV3.elevated,
          elevated: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      context.l10n.listingSelectedCount(count),
                      style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                        color: context.sdTheme3.textPrimary,
                      ),
                    ),
                  ),
                  SdButtonV3(
                    variant: SdButtonVariantV3.text,
                    label: context.l10n.commonClear,
                    size: SdButtonSizeV3.small,
                    onPressed: () =>
                        ref.read(listingSelectionProvider.notifier).clear(),
                  ),
                ],
              ),
              SizedBox(height: SdSpacingConstant.h8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SdButtonV3(
                      variant: SdButtonVariantV3.primary,
                      label: context.l10n.itemActionReprice,
                      size: SdButtonSizeV3.small,
                      expand: true,
                      onPressed: isBusy ? null : () => _reprice(context, ref),
                    ),
                  ),
                  SizedBox(width: SdSpacingConstant.w8),
                  Expanded(
                    child: SdButtonV3(
                      variant: SdButtonVariantV3.secondary,
                      label: context.l10n.listingPause,
                      size: SdButtonSizeV3.small,
                      expand: true,
                      onPressed: isBusy
                          ? null
                          : () =>
                                _setStatus(context, ref, ListingStatus.paused),
                    ),
                  ),
                  SizedBox(width: SdSpacingConstant.w8),
                  Expanded(
                    child: SdButtonV3(
                      variant: SdButtonVariantV3.outlined,
                      label: context.l10n.listingEnd,
                      size: SdButtonSizeV3.small,
                      expand: true,
                      onPressed: isBusy
                          ? null
                          : () => _setStatus(context, ref, ListingStatus.ended),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
