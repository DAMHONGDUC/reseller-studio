import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../features/subscription/domain/services/plan_gate.dart';
import '../../features/subscription/presentation/widgets/plan_block_sheet.dart';
import '../../features/subscription/providers.dart';
import '../constants/app_icon_constant.dart';
import '../constants/log_tag_constant.dart';
import '../extensions/context_extensions.dart';
import '../router/app_routes.dart';
import 'option_picker_sheet.dart';

/// The ways stock comes in — Quick add, Scan, Take stock in — asked in one
/// sheet that Inventory's create button and Home's Add stock shortcut both
/// open (`lib/features/inventory/CLAUDE.md`).
///
/// In `core/widgets/` because two features open it, and one copy is what
/// stops them offering different ways in.
final class AddStockSheet {
  /// Asks which way, then opens it.
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final String? picked = await OptionPickerSheet.show<String>(
      context,
      title: context.l10n.inventoryAddTitle,
      options: <PickerOption<String>>[
        PickerOption<String>(
          value: AppRoutes.quickAdd,
          label: context.l10n.quickAddTitle,
          caption: context.l10n.inventoryAddQuickCaption,
          icon: AppIconConstant.bolt,
        ),
        PickerOption<String>(
          value: AppRoutes.scanner,
          label: context.l10n.inventoryScan,
          caption: context.l10n.inventoryAddScanCaption,
          icon: AppIconConstant.barcodeScanner,
        ),
        PickerOption<String>(
          value: AppRoutes.intake,
          label: context.l10n.quickActionIntakeSession,
          caption: context.l10n.inventoryAddIntakeCaption,
          icon: AppIconConstant.storefront,
        ),
      ],
    );

    if (picked == null || !context.mounted) return;

    SdLogger.action(LogTagConstant.item, 'Pick a way to add stock', <
      String,
      Object?
    >{'route': picked});

    // Scan finds before it adds, so the item ceiling is not its question.
    if (picked == AppRoutes.scanner) {
      unawaited(context.push(picked));

      return;
    }

    await openGated(context, ref, picked);
  }

  /// Opens a create flow for an item, or explains why it cannot.
  ///
  /// **Checked before the form opens, never after the seller has typed.**
  /// Refusing a title someone has already entered is the worst moment to
  /// mention a plan limit, and it loses their work.
  static Future<void> openGated(
    BuildContext context,
    WidgetRef ref,
    String route,
  ) async {
    final PlanBlock block = ref.read(addItemBlockProvider);

    if (block == PlanBlock.none) {
      unawaited(context.push(route));

      return;
    }

    SdLogger.info(LogTagConstant.item, 'Add stock blocked by the plan', <
      String,
      Object?
    >{'route': route, 'block': block.name});

    await PlanBlockSheet.show(
      context,
      block: block,
      plan: ref.read(currentPlanProvider),
    );
  }
}
