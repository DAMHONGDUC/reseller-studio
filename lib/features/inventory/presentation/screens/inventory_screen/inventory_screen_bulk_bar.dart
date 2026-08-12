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
        title: 'Archive ${items.length} items?',
        message:
            'They leave your inventory and stop counting toward its value. '
            'You can put them back at any time.',
        icon: Symbols.archive_rounded,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: 'Archive',
            isPrimary: true,
            onPressed: () async {
              try {
                await ref
                    .read(itemActionsControllerProvider.notifier)
                    .archive(items);

                if (!context.mounted) return;

                ref.read(inventorySelectionProvider.notifier).clear();
                SdSnackBarUtilsV3.success(
                  context,
                  'Archived ${items.length} items',
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
          SdDialogActionV3(
            label: context.l10n.actionCancel,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Future<void> _move(BuildContext context, WidgetRef ref) async {
    final List<StorageLocation> locations =
        ref.read(locationsProvider).value ?? const <StorageLocation>[];
    final Map<String, String> paths = ref.read(locationPathsProvider);
    final List<Item> items = ref.read(selectedItemsProvider);

    if (locations.isEmpty) {
      SdSnackBarUtilsV3.info(context, 'Add a location first: More → Locations');

      return;
    }

    final String? picked = await OptionPickerSheet.show<String>(
      context,
      title: 'Move ${items.length} items to',
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
      SdSnackBarUtilsV3.success(context, 'Moved ${items.length} items');
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
                    '$count selected',
                    style: context.textTheme3.bodyMedium!.semiBold3.copyWith(
                      color: context.sdTheme3.textPrimary,
                    ),
                  ),
                ),
                SdButtonV3(
                  variant: SdButtonVariantV3.text,
                  label: 'Clear',
                  size: SdButtonSizeV3.small,
                  onPressed: () =>
                      ref.read(inventorySelectionProvider.notifier).clear(),
                ),
              ],
            ),
            SizedBox(height: SdSpacingConstant.h8),
            Row(
              children: <Widget>[
                Expanded(
                  child: SdButtonV3(
                    variant: SdButtonVariantV3.primary,
                    label: 'Reprice',
                    size: SdButtonSizeV3.small,
                    expand: true,
                    onPressed: () => RepriceSheet.show(
                      context,
                      ref.read(selectedItemsProvider),
                    ),
                  ),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(
                  child: SdButtonV3(
                    variant: SdButtonVariantV3.secondary,
                    label: 'Move',
                    size: SdButtonSizeV3.small,
                    expand: true,
                    onPressed: () => _move(context, ref),
                  ),
                ),
                SizedBox(width: SdSpacingConstant.w8),
                Expanded(
                  child: SdButtonV3(
                    variant: SdButtonVariantV3.outlined,
                    label: 'Archive',
                    size: SdButtonSizeV3.small,
                    expand: true,
                    onPressed: () => _archive(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
