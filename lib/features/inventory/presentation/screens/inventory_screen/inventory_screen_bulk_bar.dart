part of 'inventory_screen.dart';

/// The bar that appears once rows are ticked.
///
/// **Bulk is a first-class requirement** (hard rule 16, plan §7): reprice,
/// move and archive are things a seller does to forty rows at once, and a
/// screen that could only edit one at a time is why people keep using
/// spreadsheets.
///
/// It replaces the FAB rather than stacking above it — two floating controls
/// competing for the same corner is how the wrong one gets tapped.
class _BulkActionBar extends ConsumerWidget {
  const _BulkActionBar();

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final List<Item> items = ref.read(selectedItemsProvider);

    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.bulkArchiveConfirmTitle(items.length),
        message: context.l10n.bulkArchiveConfirmBody,
        icon: AppIconConstant.archive,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.itemActionArchive,
            isPrimary: true,
            onPressed: () async {
              try {
                await ref
                    .read(itemActionsControllerProvider.notifier)
                    .archive(items);

                if (!context.mounted) return;

                ref.read(inventorySelectionProvider.notifier).clear();
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
  }

  /// Clears the selection on success, so the bar leaves with the work it did.
  Future<void> _list(BuildContext context, WidgetRef ref) async {
    final bool? listed = await BulkListSheet.show(
      context,
      ref.read(selectedItemsProvider),
    );

    if (listed != true || !context.mounted) return;

    ref.read(inventorySelectionProvider.notifier).clear();
  }

  /// File the selection under a buying trip.
  ///
  /// Bulk because a trip arrives as a box of forty, and filing them one at a
  /// time on each item form is the work this screen exists to remove
  /// (hard rule 16).
  Future<void> _assignPurchase(BuildContext context, WidgetRef ref) async {
    final List<Purchase> purchases =
        ref.read(purchasesProvider).value ?? const <Purchase>[];
    final List<Item> items = ref.read(selectedItemsProvider);
    final Map<String, String> sources = ref.read(sourceNamesProvider);

    if (purchases.isEmpty) {
      SdSnackBarUtilsV3.info(context, context.l10n.itemAddPurchaseFirst);

      return;
    }

    final String? picked = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.bulkAssignPurchaseTitle(items.length),
      options: purchases
          .map(
            (Purchase purchase) => PickerOption<String>(
              value: purchase.id,
              label: DateTimeUtils.mediumDate(
                purchase.purchaseDate,
                locale: context.localeTag,
              ),
              caption: sources[purchase.sourceId],
            ),
          )
          .toList(),
    );

    if (picked == null || !context.mounted) return;

    try {
      await ref
          .read(itemActionsControllerProvider.notifier)
          .assignPurchase(
            items,
            purchases.firstWhere((Purchase row) => row.id == picked),
          );

      if (!context.mounted) return;

      ref.read(inventorySelectionProvider.notifier).clear();
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  Future<void> _move(BuildContext context, WidgetRef ref) async {
    final List<StorageLocation> locations =
        ref.read(locationsProvider).value ?? const <StorageLocation>[];
    final Map<String, String> paths = ref.read(locationPathsProvider);
    final List<Item> items = ref.read(selectedItemsProvider);

    if (locations.isEmpty) {
      SdSnackBarUtilsV3.info(context, context.l10n.itemAddLocationFirst);

      return;
    }

    final String? picked = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.bulkMoveTitle(items.length),
      options: locations
          .map(
            (StorageLocation location) => PickerOption<String>(
              value: location.id,
              label: paths[location.id] ?? location.name,
            ),
          )
          .toList(),
    );

    if (picked == null || !context.mounted) return;

    try {
      await ref
          .read(itemActionsControllerProvider.notifier)
          .move(items, picked);

      if (!context.mounted) return;

      ref.read(inventorySelectionProvider.notifier).clear();
    } catch (error) {
      // Already logged by the controller.
      if (!context.mounted) return;

      SdSnackBarUtilsV3.error(
        context,
        FailurePresenter.message(context, error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(inventorySelectionProvider).length;

    return Padding(
      padding: EdgeInsets.only(
        left: SdContentPaddingV3.horizontal,
        right: SdContentPaddingV3.horizontal,
        bottom: SdContentPaddingV3.floatingBarInset(context),
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
                    context.l10n.inventorySelectedCount(count),
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
                      ref.read(inventorySelectionProvider.notifier).clear(),
                ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h8),
            // Its own full-width row above the three: listing is the verb a
            // whole session is made of, and reprice, move and archive are the
            // maintenance around it. Four small buttons in one row would have
            // made the main action the narrowest thing on the bar.
            SdButtonV3(
              variant: SdButtonVariantV3.primary,
              label: context.l10n.itemActionList,
              size: SdButtonSizeV3.small,
              expand: true,
              onPressed: () => _list(context, ref),
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
                    onPressed: () => RepriceSheet.show(
                      context,
                      ref,
                      ref.read(selectedItemsProvider),
                    ),
                  ),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(
                  child: SdButtonV3(
                    variant: SdButtonVariantV3.outlined,
                    label: context.l10n.itemActionMove,
                    size: SdButtonSizeV3.small,
                    expand: true,
                    onPressed: () => _move(context, ref),
                  ),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(
                  child: SdButtonV3(
                    variant: SdButtonVariantV3.outlined,
                    label: context.l10n.itemActionArchive,
                    size: SdButtonSizeV3.small,
                    expand: true,
                    onPressed: () => _archive(context, ref),
                  ),
                ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h8),
            // Its own row rather than a fourth in the one above: the comment
            // there holds — four small buttons in a row makes every one of
            // them the narrowest thing on the bar.
            SdButtonV3(
              variant: SdButtonVariantV3.outlined,
              label: context.l10n.bulkAssignPurchase,
              size: SdButtonSizeV3.small,
              expand: true,
              onPressed: () => _assignPurchase(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
