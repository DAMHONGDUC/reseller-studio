part of 'listings_screen.dart';

/// The listings left live on items that have gone, with one way to end them
/// all (plan §13 "delist after sale"). Absent when there are none.
class _ToEndBanner extends ConsumerWidget {
  const _ToEndBanner();

  Future<void> _endAll(
    BuildContext context,
    WidgetRef ref,
    List<Listing> listings,
  ) => showSdDialogV3(
    context,
    SdDialogV3(
      title: context.l10n.listingsToEndTitle(listings.length),
      message: context.l10n.listingsToEndDetail,
      icon: AppIconConstant.warning,
      actions: <SdDialogActionV3>[
        SdDialogActionV3(
          label: context.l10n.listingsEndAll,
          isDestructive: true,
          onPressed: () async {
            try {
              await ref
                  .read(listingActionsControllerProvider.notifier)
                  .setStatus(listings, ListingStatus.ended);
              if (!context.mounted) return;
              SdSnackBarUtilsV3.success(
                context,
                context.l10n.listingStatusChanged(
                  listings.length,
                  ListingStatusLabel.of(context, ListingStatus.ended),
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
          },
        ),
        SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Listing> toEnd = ref.watch(listingsToEndProvider);

    if (toEnd.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SdContentPaddingV3.horizontal,
        0,
        SdContentPaddingV3.horizontal,
        SdContentPaddingV3.topGap,
      ),
      child: AppStatusCard(
        icon: AppIconConstant.warning,
        tint: context.sdTheme3.danger,
        borderColor: context.sdTheme3.danger,
        title: context.l10n.listingsToEndTitle(toEnd.length),
        detail: context.l10n.listingsToEndDetail,
        onTap: () => _endAll(context, ref, toEnd),
      ),
    );
  }
}
