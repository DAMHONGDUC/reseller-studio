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

  /// With rules on file, Reprice first asks how: one typed price, or a rule.
  /// With none, it opens the price box directly — no extra step for a
  /// business that never made a rule.
  Future<void> _reprice(BuildContext context, WidgetRef ref) async {
    final List<PricingRule> rules = ref.read(activePricingRulesProvider);

    if (rules.isEmpty) return _typePrice(context, ref);

    final String? picked = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.listingRepriceTitle(
        ref.read(selectedListingsProvider).length,
      ),
      options: <PickerOption<String>>[
        PickerOption<String>(
          value: _typedPrice,
          label: context.l10n.listingRepriceTypePrice,
          icon: AppIconConstant.edit,
        ),
        for (final PricingRule rule in rules)
          PickerOption<String>(
            value: rule.id,
            label: rule.name,
            caption: PricingRuleLabel.summary(context, rule),
            icon: AppIconConstant.sell,
          ),
      ],
    );

    if (picked == null || !context.mounted) return;
    if (picked == _typedPrice) return _typePrice(context, ref);

    final PricingRule? rule = rules
        .where((PricingRule rule) => rule.id == picked)
        .firstOrNull;

    if (rule != null) return _applyRule(context, ref, rule);
  }

  /// The picker's value for "type a price" — no rule id is empty.
  static const String _typedPrice = '';

  Future<void> _applyRule(
    BuildContext context,
    WidgetRef ref,
    PricingRule rule,
  ) async {
    final List<Listing> listings = ref.read(selectedListingsProvider);

    try {
      final RuleRepricing result = await ref
          .read(listingActionsControllerProvider.notifier)
          .applyRule(listings, rule);

      if (!context.mounted) return;

      ref.read(listingSelectionProvider.notifier).clear();
      SdSnackBarUtilsV3.success(
        context,
        <String>[
          context.l10n.listingRuleApplied(result.repriced.length, rule.name),
          if (result.skipped > 0)
            context.l10n.listingRuleSkipped(result.skipped),
        ].join('\n'),
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

  Future<void> _typePrice(BuildContext context, WidgetRef ref) {
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

  /// Take the seller's word that these are now posted on the platform.
  Future<void> _markLive(BuildContext context, WidgetRef ref) async {
    final List<Listing> listings = ref.read(selectedListingsProvider);

    try {
      await ref
          .read(listingActionsControllerProvider.notifier)
          .markLive(listings);

      if (!context.mounted) return;

      ref.read(listingSelectionProvider.notifier).clear();
      SdSnackBarUtilsV3.success(
        context,
        context.l10n.listingStatusChanged(
          listings.length,
          ListingStatusLabel.of(context, ListingStatus.active),
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
              // Its own full-width row above the rest: posting is the state
              // change this screen exists to record, and everything under it
              // is what happens to a listing afterwards.
              SdButtonV3(
                variant: SdButtonVariantV3.primary,
                label: context.l10n.listingMarkLive,
                size: SdButtonSizeV3.small,
                expand: true,
                onPressed: isBusy ? null : () => _markLive(context, ref),
              ),
              SizedBox(height: SdSpacingConstant.h8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SdButtonV3(
                      variant: SdButtonVariantV3.secondary,
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
