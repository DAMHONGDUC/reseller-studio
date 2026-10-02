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
import 'item_quick_actions.dart';

/// Everything a seller can do to one item, in one sheet (plan §7).
///
/// **The actions that would be refused are shown, not hidden**, and tapping
/// one says which requirement is missing. Hiding "Mark sold" from an item
/// nobody has counted teaches nothing; "Add a quantity" teaches the rule and
/// points at the fix.
///
/// **Marketplaces are not in here** — owner's rule. That question is answered
/// on the detail screen, under Price, where the prices the seller came to
/// change already are.
class ItemActionsSheet extends ConsumerWidget {
  const ItemActionsSheet({
    required this.item,
    this.isOnDetail = false,
    super.key,
  });

  final Item item;

  /// True when the sheet was opened from the item detail screen, which is the
  /// one place Edit is not drawn — it would push the screen underneath it.
  final bool isOnDetail;

  static Future<void> show(
    BuildContext context,
    Item item, {
    bool isOnDetail = false,
  }) => showSdBottomSheetV3<void>(
    context: context,
    builder: (BuildContext context) =>
        ItemActionsSheet(item: item, isOnDetail: isOnDetail),
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
      () => ref.read(itemActionsControllerProvider.notifier).move(<Item>[
        item,
      ], picked),
    );
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) => _run(
    context,
    () =>
        ref.read(itemActionsControllerProvider.notifier).archive(<Item>[item]),
  );

  Future<void> _makeInStock(BuildContext context, WidgetRef ref) => _run(
    context,
    () => ref.read(itemActionsControllerProvider.notifier).makeInStock(<Item>[
      item,
    ]),
  );

  Future<void> _restore(BuildContext context, WidgetRef ref) => _run(
    context,
    () =>
        ref.read(itemActionsControllerProvider.notifier).restore(<Item>[item]),
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
              () => ref
                  .read(itemActionsControllerProvider.notifier)
                  .delete(item.id),
            ),
          ),
          SdDialogActionV3(label: context.l10n.actionCancel, onPressed: () {}),
        ],
      ),
    );
  }

  /// Runs an action, closes its sheet, and presents failures only.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      await action();

      if (!context.mounted) return;

      if (navigator.canPop()) navigator.pop();
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
    final bool isOnHand = item.status.isOnHand;

    final List<Widget> actions = <Widget>[
      // **Edit is the way into the record** — owner's rule. The rows below are
      // single verbs; a title, a count or a price is changed on the detail
      // screen, and from the list there was no step to it but closing the
      // sheet and tapping the card underneath.
      if (!isOnDetail)
        AppSheetActionRow(
          icon: AppIconConstant.edit,
          label: context.l10n.actionEdit,
          onTap: () {
            final GoRouter router = GoRouter.of(context);

            Navigator.of(context).pop();
            router.push(AppRoutes.item(item.id));
          },
        ),
      AppSheetActionRow(
        icon: AppIconConstant.priceChange,
        label: context.l10n.itemActionReprice,
        onTap: () => ItemQuickActions.reprice(
          context,
          ref,
          item,
          closeSheet: Navigator.of(context).pop,
        ),
      ),
      AppSheetActionRow(
        icon: AppIconConstant.shelves,
        label: context.l10n.itemActionMove,
        onTap: () => _move(context, ref),
      ),
      AppSheetActionRow(
        icon: AppIconConstant.payments,
        label: context.l10n.itemActionMarkSold,
        onTap: () => ItemQuickActions.markSold(
          context,
          ref,
          item,
          closeSheet: Navigator.of(context).pop,
        ),
      ),
      // **A draft is not stock until the seller says so** — owner's rule, and
      // the row that says it. Only a draft can take it: everything else is
      // already on the shelf or has left it.
      if (item.status == ItemStatus.draft)
        AppSheetActionRow(
          icon: AppIconConstant.inventory,
          label: context.l10n.itemActionMakeInStock,
          onTap: () => _guarded(
            context,
            ref,
            ItemStatus.inStock,
            () => _makeInStock(context, ref),
          ),
        ),
      // **Archive, or come back — decided by whether the item is on the shelf,
      // not by whether it is archived.** A sold item had no way back at all:
      // the row said Archive, and the only route to stock was archiving it
      // first and then undoing that.
      AppSheetActionRow(
        icon: isOnHand ? AppIconConstant.archive : AppIconConstant.unarchive,
        label: isOnHand
            ? context.l10n.itemActionArchive
            : context.l10n.itemActionRestore,
        onTap: () => isOnHand
            ? _archive(context, ref)
            : _guarded(
                context,
                ref,
                ItemStatus.inStock,
                () => _restore(context, ref),
              ),
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
      closeTooltip: context.l10n.commonClose,
      child: AppSheetOptionList(
        itemCount: actions.length,
        itemBuilder: (BuildContext context, int index) => actions[index],
      ),
    );
  }
}
