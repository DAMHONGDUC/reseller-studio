import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_design/index.dart';

import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/storage_location.dart';
import '../../domain/enums/item_status.dart';
import '../../domain/services/item_transition.dart';
import '../../item_block_presenter.dart';
import '../../providers.dart';
import '../controllers/item_actions_controller.dart';
import 'list_item_sheet.dart';
import 'mark_sold_sheet.dart';
import 'reprice_sheet.dart';

/// Everything a seller can do to one item, in one sheet (plan §7).
///
/// **The actions that would be refused are shown, not hidden**, and tapping
/// one says which requirement is missing. Hiding "List" from an item with no
/// price teaches nothing; "Add an asking price to list this" teaches the rule
/// and points at the fix.
class ItemActionsSheet extends ConsumerWidget {
  const ItemActionsSheet({required this.item, super.key});

  final Item item;

  static Future<void> show(BuildContext context, Item item) =>
      showSdBottomSheetV3<void>(
        context: context,
        builder: (BuildContext context) => ItemActionsSheet(item: item),
      );

  /// Runs [action] if the move is allowed, and says what is missing if not.
  void _guarded(
    BuildContext context,
    WidgetRef ref,
    ItemStatus target,
    VoidCallback action,
  ) {
    final ItemTransitionCheck check = ref
        .read(itemActionsControllerProvider.notifier)
        .check(item, target);

    if (!check.isAllowed) {
      SdSnackBarUtilsV3.error(
        context,
        ItemBlockPresenter.messages(context, check.blocks),
      );

      return;
    }

    action();
  }

  Future<void> _move(BuildContext context, WidgetRef ref) async {
    final List<StorageLocation> locations =
        ref.read(locationsProvider).value ?? const <StorageLocation>[];
    final Map<String, String> paths = ref.read(locationPathsProvider);

    if (locations.isEmpty) {
      SdSnackBarUtilsV3.info(context, context.l10n.itemAddLocationFirst);

      return;
    }

    final String? picked = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.itemActionMoveTo,
      selected: item.locationId,
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

    await _run(
      context,
      ref,
      () => ref.read(itemActionsControllerProvider.notifier).move(<Item>[
        item,
      ], picked),
      context.l10n.itemMoved,
    );
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) => _run(
    context,
    ref,
    () =>
        ref.read(itemActionsControllerProvider.notifier).archive(<Item>[item]),
    context.l10n.itemArchived,
  );

  Future<void> _restore(BuildContext context, WidgetRef ref) => _run(
    context,
    ref,
    () =>
        ref.read(itemActionsControllerProvider.notifier).restore(<Item>[item]),
    context.l10n.itemRestored,
  );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    await showSdDialogV3(
      context,
      SdDialogV3(
        title: context.l10n.itemDeleteConfirmTitle,
        message: context.l10n.itemDeleteConfirmBody,
        icon: Symbols.warning_rounded,
        actions: <SdDialogActionV3>[
          SdDialogActionV3(
            label: context.l10n.actionDelete,
            isDestructive: true,
            onPressed: () => _run(
              context,
              ref,
              () => ref
                  .read(itemActionsControllerProvider.notifier)
                  .delete(item.id),
              context.l10n.commonDeleted,
            ),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  /// The one place an action's result becomes a message.
  ///
  /// Closes the sheet first so the confirmation is not covered by the very
  /// sheet that raised it.
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String done,
  ) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      await action();

      if (!context.mounted) return;

      if (navigator.canPop()) navigator.pop();

      SdSnackBarUtilsV3.success(context, done);
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
    final bool isArchived = item.status == ItemStatus.archived;

    return SdBottomSheetV3(
      title: item.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ActionRow(
            icon: Symbols.edit_rounded,
            label: context.l10n.actionEdit,
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.editItem(item.id));
            },
          ),
          _ActionRow(
            icon: Symbols.sell_rounded,
            label: context.l10n.itemActionList,
            onTap: () => _guarded(context, ref, ItemStatus.listed, () {
              Navigator.of(context).pop();
              ListItemSheet.show(context, item);
            }),
          ),
          _ActionRow(
            icon: Symbols.share_rounded,
            label: context.l10n.itemActionCrossList,
            onTap: () {
              final ItemTransitionCheck check = ref
                  .read(itemActionsControllerProvider.notifier)
                  .crossListCheck(item);

              if (!check.isAllowed) {
                SdSnackBarUtilsV3.error(
                  context,
                  ItemBlockPresenter.messages(context, check.blocks),
                );

                return;
              }

              Navigator.of(context).pop();
              context.push(AppRoutes.crossList(item.id));
            },
          ),
          _ActionRow(
            icon: Symbols.price_change_rounded,
            label: context.l10n.itemActionReprice,
            onTap: () {
              Navigator.of(context).pop();
              RepriceSheet.show(context, <Item>[item]);
            },
          ),
          _ActionRow(
            icon: Symbols.shelves,
            label: context.l10n.itemActionMove,
            onTap: () => _move(context, ref),
          ),
          _ActionRow(
            icon: Symbols.payments_rounded,
            label: context.l10n.itemActionMarkSold,
            onTap: () => _guarded(context, ref, ItemStatus.sold, () {
              Navigator.of(context).pop();
              MarkSoldSheet.show(context, item);
            }),
          ),
          _ActionRow(
            icon: isArchived
                ? Symbols.unarchive_rounded
                : Symbols.archive_rounded,
            label: isArchived
                ? context.l10n.itemActionRestore
                : context.l10n.itemActionArchive,
            onTap: () =>
                isArchived ? _restore(context, ref) : _archive(context, ref),
          ),
          _ActionRow(
            icon: Symbols.delete_rounded,
            label: context.l10n.actionDelete,
            isDestructive: true,
            onTap: () {
              Navigator.of(context).pop();
              _confirmDelete(context, ref);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = isDestructive
        ? context.sdTheme3.danger
        : context.sdTheme3.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: SdRadiusV3.cardAll,
      child: Padding(
        padding: SdContentPaddingV3.row,
        child: Row(
          children: <Widget>[
            SdIconV3(icon, color: tint),
            SizedBox(width: SdSpacingConstant.w12),
            Text(
              label,
              style: context.textTheme3.bodyMedium!.copyWith(color: tint),
            ),
          ],
        ),
      ),
    );
  }
}
