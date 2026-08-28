import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/app_icon_constant.dart';
import '../../../../core/error/failure_presenter.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_sheet_action_row.dart';
import '../../../../core/widgets/app_sheet_option_list.dart';
import '../../../../core/widgets/option_picker_sheet.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/storage_location.dart';
import '../../domain/enums/item_status.dart';
import '../../domain/services/item_transition.dart';
import '../../item_block_presenter.dart';
import '../../providers.dart';
import '../controllers/item_actions_controller.dart';
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
        icon: AppIconConstant.warning,
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

    final List<Widget> actions = <Widget>[
      AppSheetActionRow(
        icon: AppIconConstant.edit,
        label: context.l10n.actionEdit,
        onTap: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.editItem(item.id));
        },
      ),
      // **One List row, not List and Cross-list** — owner's rule. The two
      // read as the same verb to anybody who has not learned the difference,
      // and the narrower one stopped working after the first listing: a
      // seller who had listed on eBay tapped List, got a block message, and
      // the thing they actually wanted was the row underneath.
      AppSheetActionRow(
        icon: AppIconConstant.sell,
        label: context.l10n.itemActionList,
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
      AppSheetActionRow(
        icon: AppIconConstant.priceChange,
        label: context.l10n.itemActionReprice,
        onTap: () {
          Navigator.of(context).pop();
          RepriceSheet.show(context, ref, <Item>[item]);
        },
      ),
      AppSheetActionRow(
        icon: AppIconConstant.shelves,
        label: context.l10n.itemActionMove,
        onTap: () => _move(context, ref),
      ),
      AppSheetActionRow(
        icon: AppIconConstant.payments,
        label: context.l10n.itemActionMarkSold,
        onTap: () => _guarded(context, ref, ItemStatus.sold, () {
          Navigator.of(context).pop();
          MarkSoldSheet.show(context, item);
        }),
      ),
      AppSheetActionRow(
        icon: isArchived ? AppIconConstant.unarchive : AppIconConstant.archive,
        label: isArchived
            ? context.l10n.itemActionRestore
            : context.l10n.itemActionArchive,
        onTap: () =>
            isArchived ? _restore(context, ref) : _archive(context, ref),
      ),
      AppSheetActionRow(
        icon: AppIconConstant.delete,
        label: context.l10n.actionDelete,
        isDestructive: true,
        onTap: () {
          Navigator.of(context).pop();
          _confirmDelete(context, ref);
        },
      ),
    ];

    return SdBottomSheetV3(
      title: item.title,
      child: AppSheetOptionList(
        itemCount: actions.length,
        itemBuilder: (BuildContext context, int index) => actions[index],
      ),
    );
  }
}
