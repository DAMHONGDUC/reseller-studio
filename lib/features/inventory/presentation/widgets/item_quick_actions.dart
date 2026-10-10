import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/widgets/mark_sold_sheet.dart';
import '../../../subscription/domain/services/plan_gate.dart';
import '../../../subscription/presentation/widgets/plan_block_sheet.dart';
import '../../../subscription/providers.dart';
import '../../domain/entities/item.dart';
import '../../domain/enums/item_status.dart';
import '../../domain/services/item_transition.dart';
import '../../item_block_presenter.dart';
import '../controllers/item_actions_controller.dart';
import 'reprice_sheet.dart';

/// The two verbs a seller reaches for most — reprice and mark sold — with
/// the rules that guard them, written once.
///
/// **One owner for the guard.** The actions sheet, the detail screen's pinned
/// bar and the inventory card's inline button all start the same moves; a
/// second copy of the plan check or the transition check is how one door
/// ends up letting through a sale another refuses.
///
/// [closeSheet] runs just before a new sheet opens, so a caller that is
/// itself a sheet steps aside first. A refusal leaves it open, so the seller
/// still sees what they tapped.
final class ItemQuickActions {
  static Future<void> reprice(
    BuildContext context,
    WidgetRef ref,
    Item item, {
    VoidCallback? closeSheet,
  }) async {
    closeSheet?.call();
    await RepriceSheet.show(context, ref, <Item>[item]);
  }

  static Future<void> markSold(
    BuildContext context,
    WidgetRef ref,
    Item item, {
    VoidCallback? closeSheet,
  }) async {
    final PlanBlock block = ref.read(addOrderBlockProvider);

    if (block != PlanBlock.none) {
      closeSheet?.call();
      await PlanBlockSheet.show(
        context,
        block: block,
        plan: ref.read(currentPlanProvider),
      );

      return;
    }

    final ItemTransitionCheck check = ref
        .read(itemActionsControllerProvider.notifier)
        .check(item, ItemStatus.sold);

    if (!check.isAllowed) {
      SdSnackBarUtilsV3.error(
        context,
        ItemBlockPresenter.messages(context, check.blocks),
      );

      return;
    }

    closeSheet?.call();
    // One item: selling several at once starts from the Orders tab, where
    // the seller is already picking rather than already inside one record.
    await MarkSoldSheet.show(context, <Item>[item]);
  }
}
